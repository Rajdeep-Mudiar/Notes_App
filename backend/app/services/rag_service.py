import json
import logging
import re
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
import requests

from app.repositories.ai_repository import AiRepository
from app.schemas.ai import (
    ChatMessageModel,
    ChatRequest,
    ChatResponse,
    CitationItemModel,
    FlashcardGenerateRequest,
    FlashcardGenerateResponse,
    FlashcardItemModel,
    QuizGenerateRequest,
    QuizGenerateResponse,
    QuizQuestionModel,
    StudyModeEnum,
    SummaryGenerateRequest,
    SummaryGenerateResponse,
)
from app.schemas.ingestion import SemanticSearchQuery
from app.services.ingestion_service import IngestionService

logger = logging.getLogger(__name__)


class RagService:
    """Retrieval-Augmented Generation (RAG) and AI Study Assistant Service."""

    _groq_index: int = 0

    def __init__(
        self,
        ingestion_service: IngestionService,
        ai_repo: AiRepository,
        groq_api_keys: Optional[str] = None,
        groq_model: str = "qwen/qwen3.8-27b",
        gemini_api_key: Optional[str] = None,
        hf_api_key: Optional[str] = None,
        hf_chat_model: str = "meta-llama/Llama-3.2-3B-Instruct",
    ):
        self.ingestion_service = ingestion_service
        self.ai_repo = ai_repo
        self.groq_keys = [k.strip() for k in (groq_api_keys or "").split(",") if k.strip()]
        self.groq_model = groq_model or "qwen/qwen3.8-27b"
        self.gemini_api_key = gemini_api_key
        self.hf_api_key = hf_api_key
        self.hf_chat_model = hf_chat_model or "meta-llama/Llama-3.2-3B-Instruct"

    async def chat_grounded(self, user_id: str, req: ChatRequest) -> ChatResponse:
        """Perform grounded Q&A with in-text citations using retrieved course knowledge."""
        search_res = await self.ingestion_service.search_similar_chunks(
            user_id=user_id,
            search_query=SemanticSearchQuery(
                query=req.message,
                subject_id=req.subject_id,
                top_k=5,
                similarity_threshold=0.1,
            ),
        )

        citations: List[CitationItemModel] = []
        context_blocks: List[str] = []

        for idx, item in enumerate(search_res.results):
            citation = CitationItemModel(
                chunk_id=item.chunk_id,
                source_id=item.source_id,
                source_name=item.source_name,
                source_type=item.source_type,
                subject_id=item.subject_id,
                page_or_section=item.page_or_section,
                snippet=item.text_content[:200] + ("..." if len(item.text_content) > 200 else ""),
                similarity_score=item.similarity_score,
            )
            citations.append(citation)

            loc = f", {item.page_or_section}" if item.page_or_section else ""
            context_blocks.append(
                f"[Source {idx + 1}: {item.source_name}{loc}]\n{item.text_content}"
            )

        reply = await self._synthesize_chat_reply(
            user_question=req.message,
            context_blocks=context_blocks,
            citations=citations,
            history=req.history,
        )

        user_msg = ChatMessageModel(
            role="user",
            content=req.message,
        ).model_dump()

        assistant_msg = ChatMessageModel(
            role="assistant",
            content=reply,
            citations=citations,
        ).model_dump()

        session_title = req.message[:40] + ("..." if len(req.message) > 40 else "")
        session_id = await self.ai_repo.save_turn(
            user_id=user_id,
            session_id=req.session_id,
            title=session_title,
            subject_id=req.subject_id,
            user_msg=user_msg,
            assistant_msg=assistant_msg,
        )

        return ChatResponse(
            session_id=session_id,
            reply=reply,
            citations=citations,
            mode=StudyModeEnum.CHAT,
        )

    async def _synthesize_chat_reply(
        self,
        user_question: str,
        context_blocks: List[str],
        citations: List[CitationItemModel],
        history: List[ChatMessageModel],
    ) -> str:
        """Generate response via LLM (Gemini / HF) or dynamic grounded synthesis."""
        system_instruction = (
            "You are Notoo AI, an intelligent, friendly, and encouraging academic study assistant for university students. "
            "Your task is to answer the student's questions clearly, accurately, and thoroughly. "
            "When course excerpts are provided, cite sources cleanly in the format [Source Name, Page/Section]. "
            "Use clean markdown with clear headings, bullet points, and code/math blocks. "
            "If the student asks a general question, greeting, or concept question without indexed files, answer helpfully with clear academic principles."
        )

        context_str = "\n\n".join(context_blocks) if context_blocks else "No specific course excerpts indexed for this query."
        user_prompt = f"Course Material Excerpts:\n{context_str}\n\nStudent Question:\n{user_question}"

        # 1. Try LLM (Gemini / Hugging Face)
        llm_reply = self._call_llm_text(
            prompt=user_prompt,
            system_instruction=system_instruction,
            history=history,
        )
        if llm_reply and len(llm_reply.strip()) > 20:
            return llm_reply.strip()

        # Fallback intelligent study synthesizer
        if not context_blocks:
            return (
                f"I couldn't find indexed course documents for **\"{user_question}\"** in this workspace yet.\n\n"
                "💡 *Tip: Upload your lecture slides, notes, or reading files and click 'Index for AI' to get grounded answers.*"
            )

        primary_citation = citations[0]
        bullet_points = []
        for c in citations[:3]:
            section_tag = f" ({c.page_or_section})" if c.page_or_section else ""
            bullet_points.append(f"* **{c.source_name}{section_tag}**: {c.snippet.strip()}")

        bullet_text = "\n".join(bullet_points)
        source_badge = f"[{primary_citation.source_name}, {primary_citation.page_or_section or 'Course Notes'}]"

        return (
            f"Based on your course materials in **{source_badge}**:\n\n"
            f"{bullet_text}\n\n"
            f"### Key Concept Summary\n"
            f"> \"{primary_citation.snippet.replace('...', '')}\"\n\n"
            f"**Study Insight**: When preparing for assessments, connect this topic with related lecture themes and review practical examples."
        )

    # =========================================================================
    # QUIZ GENERATION
    # =========================================================================

    async def generate_quiz(self, user_id: str, req: QuizGenerateRequest) -> QuizGenerateResponse:
        """Generate multiple-choice practice quiz questions grounded in course chunks."""
        search_query = req.topic or "concepts definitions algorithms key formulas properties"
        search_res = await self.ingestion_service.search_similar_chunks(
            user_id=user_id,
            search_query=SemanticSearchQuery(
                query=search_query,
                subject_id=req.subject_id,
                top_k=max(req.num_questions * 2, 8),
            ),
        )

        chunks = search_res.results
        context_str = "\n\n".join([f"[{c.source_name}]: {c.text_content}" for c in chunks[:6]])

        if chunks:
            system_instruction = (
                "You are an expert university professor creating an assessment quiz. "
                "Generate rigorous, high-quality multiple choice questions based on the provided course material. "
                "Return a JSON array where each object has:\n"
                "- 'question': string\n"
                "- 'options': list of exactly 4 strings\n"
                "- 'correct_option_index': integer (0, 1, 2, or 3)\n"
                "- 'explanation': string explaining why the answer is correct\n"
                "Only return the valid JSON array, without extra markdown or commentary."
            )
            prompt = (
                f"Course Material:\n{context_str}\n\n"
                f"Generate {req.num_questions} multiple-choice questions on topic: '{req.topic or 'General Course Topics'}'. "
                f"Ensure options are plausible and one is undeniably correct."
            )

            json_data = self._call_llm_json(prompt, system_instruction)
            if json_data and isinstance(json_data, list) and len(json_data) > 0:
                questions: List[QuizQuestionModel] = []
                for idx, q in enumerate(json_data[: req.num_questions]):
                    if isinstance(q, dict) and "question" in q and "options" in q:
                        opts = [str(o) for o in q.get("options", [])]
                        if len(opts) >= 2:
                            while len(opts) < 4:
                                opts.append(f"None of the above option {len(opts) + 1}")
                            corr_idx = int(q.get("correct_option_index", 0))
                            if corr_idx < 0 or corr_idx >= len(opts):
                                corr_idx = 0
                            
                            citation = None
                            if idx < len(chunks):
                                c = chunks[idx]
                                citation = CitationItemModel(
                                    chunk_id=c.chunk_id,
                                    source_id=c.source_id,
                                    source_name=c.source_name,
                                    source_type=c.source_type,
                                    subject_id=c.subject_id,
                                    page_or_section=c.page_or_section,
                                    snippet=c.text_content[:160] + "...",
                                    similarity_score=c.similarity_score,
                                )

                            questions.append(
                                QuizQuestionModel(
                                    id=f"q_{idx + 1}_{uuid.uuid4().hex[:6]}",
                                    question=str(q.get("question")),
                                    options=opts[:4],
                                    correct_option_index=corr_idx,
                                    explanation=str(q.get("explanation", "Verified from course materials.")),
                                    citation=citation,
                                )
                            )
                if questions:
                    return QuizGenerateResponse(
                        title=f"Practice Quiz: {req.topic or 'Course Knowledge'}",
                        subject_id=req.subject_id,
                        questions=questions,
                        total_questions=len(questions),
                    )

        # Dynamic fallback from chunks if LLM not responding or no API keys
        questions = []
        if not chunks:
            questions.append(
                QuizQuestionModel(
                    id="q_fallback_1",
                    question="Which algorithmic technique updates model parameters in the direction of the negative gradient?",
                    options=[
                        "Gradient Descent",
                        "Depth First Search",
                        "QuickSort Algorithm",
                        "Dijkstra Shortest Path"
                    ],
                    correct_option_index=0,
                    explanation="Gradient descent iteratively updates parameters in the opposite direction of the loss gradient.",
                )
            )
        else:
            for idx, chunk in enumerate(chunks[: req.num_questions]):
                text = chunk.text_content
                lines = [l.strip() for l in text.split("\n") if l.strip() and len(l.strip()) > 15]
                first_sentence = lines[0] if lines else "Core Course Concept"
                words = re.findall(r"\w+", first_sentence)
                key_term = " ".join(words[:2]) if len(words) >= 2 else "Concept"

                citation = CitationItemModel(
                    chunk_id=chunk.chunk_id,
                    source_id=chunk.source_id,
                    source_name=chunk.source_name,
                    source_type=chunk.source_type,
                    subject_id=chunk.subject_id,
                    page_or_section=chunk.page_or_section,
                    snippet=text[:160] + "...",
                    similarity_score=chunk.similarity_score,
                )

                questions.append(
                    QuizQuestionModel(
                        id=f"q_{idx + 1}_{uuid.uuid4().hex[:6]}",
                        question=f"According to '{chunk.source_name}', what is a primary characteristic of {key_term}?",
                        options=[
                            first_sentence[:120],
                            f"It operates strictly as a static read-only cache without runtime updates.",
                            f"It bypasses all algorithmic invariant constraints during execution.",
                            f"It runs in O(1) constant auxiliary space with zero state transitions.",
                        ],
                        correct_option_index=0,
                        explanation=f"Directly derived from {chunk.source_name}: \"{text[:160]}\"",
                        citation=citation,
                    )
                )

        return QuizGenerateResponse(
            title=f"Practice Quiz: {req.topic or 'Course Knowledge'}",
            subject_id=req.subject_id,
            questions=questions,
            total_questions=len(questions),
        )

    # =========================================================================
    # FLASHCARD GENERATION
    # =========================================================================

    async def generate_flashcards(self, user_id: str, req: FlashcardGenerateRequest) -> FlashcardGenerateResponse:
        """Generate structured flashcard study deck extracted from course chunks."""
        search_query = req.topic or "definitions terms formulas core concepts methods"
        search_res = await self.ingestion_service.search_similar_chunks(
            user_id=user_id,
            search_query=SemanticSearchQuery(
                query=search_query,
                subject_id=req.subject_id,
                top_k=max(req.num_cards * 2, 10),
            ),
        )

        chunks = search_res.results
        context_str = "\n\n".join([f"[{c.source_name}]: {c.text_content}" for c in chunks[:6]])

        if chunks:
            system_instruction = (
                "You are an academic flashcard creator. Generate high-yield, concise study flashcards from the provided material. "
                "Return a JSON array where each object has:\n"
                "- 'front': string (a concise term, formula name, or concept question)\n"
                "- 'back': string (a clear, accurate definition or explanation)\n"
                "- 'category': string (the sub-topic or theme)\n"
                "Only return valid JSON array."
            )
            prompt = (
                f"Course Material:\n{context_str}\n\n"
                f"Generate {req.num_cards} flashcards for topic: '{req.topic or 'Core Concepts'}'. "
                f"Focus on high-yield exam takeaways."
            )

            json_data = self._call_llm_json(prompt, system_instruction)
            if json_data and isinstance(json_data, list) and len(json_data) > 0:
                cards: List[FlashcardItemModel] = []
                for idx, item in enumerate(json_data[: req.num_cards]):
                    if isinstance(item, dict) and "front" in item and "back" in item:
                        citation = None
                        if idx < len(chunks):
                            c = chunks[idx]
                            citation = CitationItemModel(
                                chunk_id=c.chunk_id,
                                source_id=c.source_id,
                                source_name=c.source_name,
                                source_type=c.source_type,
                                subject_id=c.subject_id,
                                page_or_section=c.page_or_section,
                                snippet=c.text_content[:160] + "...",
                                similarity_score=c.similarity_score,
                            )
                        cards.append(
                            FlashcardItemModel(
                                id=f"fc_{idx + 1}_{uuid.uuid4().hex[:6]}",
                                front=str(item.get("front")),
                                back=str(item.get("back")),
                                category=str(item.get("category", req.topic or "Core Concept")),
                                citation=citation,
                            )
                        )
                if cards:
                    return FlashcardGenerateResponse(
                        title=f"Flashcards: {req.topic or 'Core Concepts'}",
                        subject_id=req.subject_id,
                        cards=cards,
                        total_cards=len(cards),
                    )

        # Fallback extraction
        cards = []
        if not chunks:
            cards.append(
                FlashcardItemModel(
                    id="fc_sample_1",
                    front="Gradient Descent",
                    back="An iterative first-order optimization algorithm for finding a local minimum of a differentiable loss function.",
                    category="Optimization",
                )
            )
        else:
            for idx, chunk in enumerate(chunks[: req.num_cards]):
                text = chunk.text_content
                lines = [l.strip() for l in text.split("\n") if l.strip()]
                front_text = chunk.page_or_section or f"Concept from {chunk.source_name}"
                if lines and len(lines[0]) < 60:
                    front_text = lines[0].replace("#", "").strip()

                back_text = text[:280] + ("..." if len(text) > 280 else "")
                citation = CitationItemModel(
                    chunk_id=chunk.chunk_id,
                    source_id=chunk.source_id,
                    source_name=chunk.source_name,
                    source_type=chunk.source_type,
                    subject_id=chunk.subject_id,
                    page_or_section=chunk.page_or_section,
                    snippet=text[:160] + "...",
                    similarity_score=chunk.similarity_score,
                )
                cards.append(
                    FlashcardItemModel(
                        id=f"fc_{idx + 1}_{uuid.uuid4().hex[:6]}",
                        front=front_text,
                        back=back_text,
                        category=chunk.source_name,
                        citation=citation,
                    )
                )

        return FlashcardGenerateResponse(
            title=f"Flashcards: {req.topic or 'Core Concepts'}",
            subject_id=req.subject_id,
            cards=cards,
            total_cards=len(cards),
        )

    # =========================================================================
    # EXAM SUMMARY GENERATION
    # =========================================================================

    async def generate_summary(self, user_id: str, req: SummaryGenerateRequest) -> SummaryGenerateResponse:
        """Generate high-yield exam revision cheat sheet."""
        search_query = req.topic or "overview summary formulas exam review concepts"
        search_res = await self.ingestion_service.search_similar_chunks(
            user_id=user_id,
            search_query=SemanticSearchQuery(
                query=search_query,
                subject_id=req.subject_id,
                top_k=8,
            ),
        )

        chunks = search_res.results
        citations = [
            CitationItemModel(
                chunk_id=c.chunk_id,
                source_id=c.source_id,
                source_name=c.source_name,
                source_type=c.source_type,
                subject_id=c.subject_id,
                page_or_section=c.page_or_section,
                snippet=c.text_content[:180] + "...",
                similarity_score=c.similarity_score,
            )
            for c in chunks
        ]

        context_str = "\n\n".join([f"[{c.source_name}]: {c.text_content}" for c in chunks[:6]])

        if chunks:
            system_instruction = (
                "You are an academic exam prep specialist. Generate a concise, high-yield revision cheat sheet based on the course materials. "
                "Return a JSON object with:\n"
                "- 'overview': string (2-3 sentences summarizing the major theme)\n"
                "- 'key_concepts': list of strings (4-6 core takeaways)\n"
                "- 'important_formulas_or_takeaways': list of strings (key mathematical formulas or definitions)\n"
                "- 'exam_tips': list of strings (3 actionable test-taking strategies)\n"
                "Only return valid JSON object."
            )
            prompt = (
                f"Course Material:\n{context_str}\n\n"
                f"Generate a revision summary for topic: '{req.topic or 'High-Yield Exam Prep'}'."
            )

            json_data = self._call_llm_json(prompt, system_instruction)
            if json_data and isinstance(json_data, dict):
                return SummaryGenerateResponse(
                    title=f"Revision Summary: {req.topic or 'High-Yield Exam Prep'}",
                    subject_id=req.subject_id,
                    overview=str(json_data.get("overview", "Comprehensive course review synthesized from indexed materials.")),
                    key_concepts=[str(c) for c in json_data.get("key_concepts", [])] or ["Master the core algorithmic definitions."],
                    important_formulas_or_takeaways=[str(f) for f in json_data.get("important_formulas_or_takeaways", [])] or ["Review foundational theorems."],
                    exam_tips=[str(t) for t in json_data.get("exam_tips", [])] or ["Verify boundary conditions on assessments."],
                    citations=citations,
                )

        # Fallback extraction
        key_concepts = []
        formulas = []
        for item in chunks:
            sentences = [s.strip() for s in item.text_content.split(".") if len(s.strip()) > 20]
            if sentences:
                key_concepts.append(f"{sentences[0]} [{item.source_name}]")
            if any(math_sym in item.text_content for math_sym in ["=", "+", "-", "*", "/", "theta", "alpha", "$"]):
                for line in item.text_content.split("\n"):
                    if any(sym in line for sym in ["=", "def ", "$$", "\\"]):
                        formulas.append(line.strip())

        return SummaryGenerateResponse(
            title=f"Revision Summary: {req.topic or 'High-Yield Exam Prep'}",
            subject_id=req.subject_id,
            overview=f"Comprehensive syllabus synthesis compiled from {len(citations)} indexed source materials.",
            key_concepts=key_concepts[:6] or ["Master the core algorithmic definitions and proof properties."],
            important_formulas_or_takeaways=formulas[:4] or ["Loss update: theta = theta - alpha * gradient(J(theta))"],
            exam_tips=[
                "Be prepared to write iterative equations and state time/space complexities on assessments.",
                "Verify all preconditions and edge cases before applying optimization theorems.",
                "Review connected lecture slides and completed assignment homework problems.",
            ],
            citations=citations,
        )

    # =========================================================================
    # LOW-LEVEL LLM CLIENT HELPERS (GROQ ROUND-ROBIN, GEMINI & HUGGING FACE)
    # =========================================================================

    def _call_llm_text(
        self,
        prompt: str,
        system_instruction: str,
        history: Optional[List[ChatMessageModel]] = None,
    ) -> Optional[str]:
        """Dispatch text generation: Groq (Round-Robin) -> Gemini -> Hugging Face."""
        # 1. Try Groq with Round-Robin key rotation if configured
        if self.groq_keys:
            try:
                ans = self._call_groq_chat(prompt, system_instruction, history=history, json_mode=False)
                if ans:
                    return ans
            except Exception as e:
                logger.warning(f"Groq Round-Robin call failed: {e}")

        # 2. Try Gemini API if configured
        if self.gemini_api_key:
            try:
                ans = self._call_gemini_generate(prompt, system_instruction, history=history)
                if ans:
                    return ans
            except Exception as e:
                logger.warning(f"Gemini API call failed: {e}")

        # 3. Try Hugging Face Chat API if configured
        if self.hf_api_key:
            try:
                ans = self._call_hf_chat(prompt, system_instruction, history=history)
                if ans:
                    return ans
            except Exception as e:
                logger.warning(f"Hugging Face API call failed: {e}")

        return None

    def _call_llm_json(
        self,
        prompt: str,
        system_instruction: str,
    ) -> Optional[Any]:
        """Dispatch JSON generation: Groq (Round-Robin) -> Gemini -> Hugging Face."""
        # 1. Try Groq JSON mode with Round-Robin key rotation
        if self.groq_keys:
            try:
                raw_reply = self._call_groq_chat(prompt, system_instruction, json_mode=True)
                if raw_reply:
                    cleaned = re.sub(r"^```(json)?", "", raw_reply.strip(), flags=re.MULTILINE)
                    cleaned = re.sub(r"```$", "", cleaned.strip(), flags=re.MULTILINE)
                    match = re.search(r"(\[.*\]|\{.*\})", cleaned, re.DOTALL)
                    if match:
                        return json.loads(match.group(1))
                    return json.loads(raw_reply)
            except Exception as e:
                logger.warning(f"Groq JSON generation failed: {e}")

        # 2. Try Gemini with JSON response schema
        if self.gemini_api_key:
            try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={self.gemini_api_key}"
                payload = {
                    "contents": [{"role": "user", "parts": [{"text": prompt}]}],
                    "systemInstruction": {"parts": [{"text": system_instruction}]},
                    "generationConfig": {
                        "responseMimeType": "application/json",
                        "temperature": 0.2,
                        "maxOutputTokens": 2048,
                    },
                }
                resp = requests.post(url, json=payload, timeout=15)
                if resp.status_code == 200:
                    data = resp.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts:
                            raw_text = parts[0].get("text", "")
                            return json.loads(raw_text)
            except Exception as e:
                logger.warning(f"Gemini JSON generation failed: {e}")

        # 3. Try HF Chat
        if self.hf_api_key:
            try:
                raw_reply = self._call_hf_chat(prompt, system_instruction)
                if raw_reply:
                    cleaned = re.sub(r"^```(json)?", "", raw_reply.strip(), flags=re.MULTILINE)
                    cleaned = re.sub(r"```$", "", cleaned.strip(), flags=re.MULTILINE)
                    match = re.search(r"(\[.*\]|\{.*\})", cleaned, re.DOTALL)
                    if match:
                        return json.loads(match.group(1))
            except Exception as e:
                logger.warning(f"HF JSON parse failed: {e}")

        return None

    def _call_groq_chat(
        self,
        prompt: str,
        system_instruction: str,
        history: Optional[List[ChatMessageModel]] = None,
        json_mode: bool = False,
    ) -> Optional[str]:
        """Call Groq API using round-robin key rotation and automatic failover across keys."""
        if not self.groq_keys:
            return None

        messages = [{"role": "system", "content": system_instruction}]
        if history:
            for h in history[-4:]:
                messages.append({"role": h.role, "content": h.content})
        messages.append({"role": "user", "content": prompt})

        payload: Dict[str, Any] = {
            "model": self.groq_model,
            "messages": messages,
            "temperature": 0.2,
            "max_tokens": 2048,
        }
        if json_mode:
            payload["response_format"] = {"type": "json_object"}

        num_keys = len(self.groq_keys)
        candidate_models = [self.groq_model]
        for m in ["qwen/qwen3.8-27b", "groq/compound-mini"]:
            if m not in candidate_models:
                candidate_models.append(m)

        for model_name in candidate_models:
            payload["model"] = model_name
            # Try each key in the pool in round-robin order
            for attempt in range(num_keys):
                idx = (RagService._groq_index + attempt) % num_keys
                api_key = self.groq_keys[idx]
                headers = {
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                }
                try:
                    resp = requests.post(
                        "https://api.groq.com/openai/v1/chat/completions",
                        headers=headers,
                        json=payload,
                        timeout=15,
                    )
                    if resp.status_code == 200:
                        data = resp.json()
                        choices = data.get("choices", [])
                        if choices:
                            content = choices[0].get("message", {}).get("content", "")
                            if content and len(content.strip()) > 0:
                                # Successfully used key, advance round-robin index for next call
                                RagService._groq_index = (idx + 1) % num_keys
                                return content.strip()
                    elif resp.status_code in (429, 401, 503):
                        logger.warning(
                            f"Groq API key #{idx + 1} returned HTTP {resp.status_code}, rotating to next key in pool..."
                        )
                        continue
                    elif resp.status_code in (404, 400):
                        logger.warning(f"Groq model '{model_name}' returned HTTP {resp.status_code}, trying next model...")
                        break
                    else:
                        logger.warning(f"Groq API error (status {resp.status_code}): {resp.text[:200]}")
                except Exception as e:
                    logger.warning(f"Groq API request with key #{idx + 1} failed: {e}")
                    continue

        return None

    def _call_gemini_generate(
        self,
        prompt: str,
        system_instruction: str,
        history: Optional[List[ChatMessageModel]] = None,
    ) -> Optional[str]:
        """Call Google Gemini 1.5 Flash content generation."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={self.gemini_api_key}"
        contents = []
        if history:
            for h in history[-4:]:
                contents.append({
                    "role": "user" if h.role == "user" else "model",
                    "parts": [{"text": h.content}],
                })
        contents.append({"role": "user", "parts": [{"text": prompt}]})

        payload = {
            "contents": contents,
            "systemInstruction": {"parts": [{"text": system_instruction}]},
            "generationConfig": {
                "temperature": 0.3,
                "maxOutputTokens": 1500,
            },
        }
        resp = requests.post(url, json=payload, timeout=15)
        if resp.status_code == 200:
            data = resp.json()
            candidates = data.get("candidates", [])
            if candidates:
                parts = candidates[0].get("content", {}).get("parts", [])
                if parts:
                    return parts[0].get("text", "")
        return None

    def _call_hf_chat(
        self,
        prompt: str,
        system_instruction: str,
        history: Optional[List[ChatMessageModel]] = None,
    ) -> Optional[str]:
        """Send prompt to Hugging Face Router or standard endpoint."""
        messages = [{"role": "system", "content": system_instruction}]
        if history:
            for h in history[-4:]:
                messages.append({"role": h.role, "content": h.content})
        messages.append({"role": "user", "content": prompt})

        endpoints = [
            "https://router.huggingface.co/hf-inference/v1/chat/completions",
            "https://api-inference.huggingface.co/v1/chat/completions",
        ]

        headers = {
            "Authorization": f"Bearer {self.hf_api_key}",
            "Content-Type": "application/json",
        }

        for ep in endpoints:
            try:
                payload = {
                    "model": self.hf_chat_model,
                    "messages": messages,
                    "max_tokens": 1024,
                    "temperature": 0.3,
                }
                resp = requests.post(ep, headers=headers, json=payload, timeout=12)
                if resp.status_code == 200:
                    data = resp.json()
                    choices = data.get("choices", [])
                    if choices:
                        content = choices[0].get("message", {}).get("content", "")
                        if content and len(content.strip()) > 5:
                            return content.strip()
            except Exception:
                pass

        return None
