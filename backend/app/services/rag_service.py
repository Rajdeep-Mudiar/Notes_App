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

    def __init__(
        self,
        ingestion_service: IngestionService,
        ai_repo: AiRepository,
        gemini_api_key: Optional[str] = None,
    ):
        self.ingestion_service = ingestion_service
        self.ai_repo = ai_repo
        self.gemini_api_key = gemini_api_key

    async def chat_grounded(self, user_id: str, req: ChatRequest) -> ChatResponse:
        """Perform grounded Q&A with in-text citations using retrieved course knowledge."""
        # 1. Retrieve top-k semantic chunks
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

        # 2. Synthesize answer with grounding
        reply = await self._synthesize_chat_reply(
            user_question=req.message,
            context_blocks=context_blocks,
            citations=citations,
            history=req.history,
        )

        # 3. Persist conversation turn
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
        """Call Gemini API or run deterministic study synthesizer."""
        if self.gemini_api_key and context_blocks:
            try:
                gemini_answer = self._call_gemini_chat(user_question, context_blocks, history)
                if gemini_answer and len(gemini_answer.strip()) > 20:
                    return gemini_answer
            except Exception as e:
                logger.warning(f"Gemini chat API call failed: {e}. Falling back to deterministic synthesizer.")

        # Fallback intelligent study synthesizer
        if not context_blocks:
            return (
                f"I couldn't find any relevant study materials indexed in your workspace for **\"{user_question}\"**.\n\n"
                "💡 *Tip: Make sure you've uploaded your lecture slides, notes, or reading files and clicked 'Index for AI'.*"
            )

        # Build structured synthesis quoting top source
        primary_citation = citations[0]
        primary_snippet = primary_citation.snippet.replace("...", "")

        bullet_points = []
        for i, c in enumerate(citations[:3]):
            section_tag = f" ({c.page_or_section})" if c.page_or_section else ""
            bullet_points.append(
                f"* **{c.source_name}{section_tag}**: {c.snippet.strip()}"
            )

        bullet_text = "\n".join(bullet_points)
        source_badge = f"[{primary_citation.source_name}, {primary_citation.page_or_section or 'General'}]"

        return (
            f"Based on your course materials in **{source_badge}**:\n\n"
            f"{bullet_text}\n\n"
            f"### Key Concept Summary\n"
            f"> \"{primary_snippet}\"\n\n"
            f"**Study Insight**: When preparing for exams, ensure you review how this connects with related lecture topics."
        )

    def _call_gemini_chat(
        self,
        question: str,
        context_blocks: List[str],
        history: List[ChatMessageModel],
    ) -> Optional[str]:
        """Send prompt to Gemini 1.5 with grounding instructions."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={self.gemini_api_key}"

        system_instruction = (
            "You are Student OS AI, an intelligent, encouraging academic study assistant for university students. "
            "Your task is to answer the student's question based strictly on the provided course material excerpts. "
            "Always cite sources in the format [Source Name, Page/Slide/Section]. Use clear markdown, bold key terms, "
            "and format code or formulas cleanly. If the material does not contain the answer, politely state so."
        )

        context_str = "\n\n".join(context_blocks)
        prompt_text = f"Context from student's course materials:\n{context_str}\n\nStudent's Question: {question}"

        payload = {
            "contents": [
                {"role": "user", "parts": [{"text": prompt_text}]}
            ],
            "systemInstruction": {
                "parts": [{"text": system_instruction}]
            },
            "generationConfig": {
                "temperature": 0.3,
                "maxOutputTokens": 1024,
            }
        }

        resp = requests.post(url, json=payload, timeout=12)
        if resp.status_code == 200:
            data = resp.json()
            candidates = data.get("candidates", [])
            if candidates:
                parts = candidates[0].get("content", {}).get("parts", [])
                if parts:
                    return parts[0].get("text", "")
        return None

    async def generate_quiz(self, user_id: str, req: QuizGenerateRequest) -> QuizGenerateResponse:
        """Generate multiple choice practice quiz questions grounded in course chunks."""
        search_query = req.topic or "concepts definitions algorithms key formulas"
        search_res = await self.ingestion_service.search_similar_chunks(
            user_id=user_id,
            search_query=SemanticSearchQuery(
                query=search_query,
                subject_id=req.subject_id,
                top_k=max(req.num_questions * 2, 8),
            ),
        )

        questions: List[QuizQuestionModel] = []
        chunks = search_res.results

        if not chunks:
            # Fallback starter question if no documents uploaded yet
            questions.append(
                QuizQuestionModel(
                    id="q_fallback_1",
                    question="Which algorithmic technique updates parameters in the direction of the negative gradient?",
                    options=[
                        "Gradient Descent",
                        "Depth First Search",
                        "QuickSort",
                        "Dijkstra's Algorithm"
                    ],
                    correct_option_index=0,
                    explanation="Gradient descent updates weights iteratively in the opposite direction of the gradient of the loss function.",
                )
            )
            return QuizGenerateResponse(
                title=f"Practice Quiz: {req.topic or 'Course Knowledge'}",
                subject_id=req.subject_id,
                questions=questions,
                total_questions=len(questions),
            )

        for idx, chunk in enumerate(chunks[: req.num_questions]):
            text = chunk.text_content
            lines = [l.strip() for l in text.split("\n") if l.strip() and len(l.strip()) > 15]

            # Extract subject topic from text
            first_sentence = lines[0] if lines else "Core Course Concept"
            snippet_words = re.findall(r"\w+", first_sentence)
            key_term = snippet_words[0] if snippet_words else "Concept"
            if len(snippet_words) >= 2:
                key_term = f"{snippet_words[0]} {snippet_words[1]}"

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

            q_text = f"According to '{chunk.source_name}', which statement accurately describes {key_term}?"
            correct_opt = first_sentence[:120]
            distractor_1 = f"It is an unrelated static structure not modified during {key_term} execution."
            distractor_2 = f"It calculates quadratic polynomial interpolation without {key_term} constraints."
            distractor_3 = f"It runs exclusively in constant O(1) space with zero parameter updates."

            options = [correct_opt, distractor_1, distractor_2, distractor_3]

            questions.append(
                QuizQuestionModel(
                    id=f"q_{idx + 1}_{uuid.uuid4().hex[:6]}",
                    question=q_text,
                    options=options,
                    correct_option_index=0,
                    explanation=f"Directly derived from {chunk.source_name} ({chunk.page_or_section or 'General'}): \"{text[:180]}\"",
                    citation=citation,
                )
            )

        return QuizGenerateResponse(
            title=f"Practice Quiz: {req.topic or 'Course Knowledge'}",
            subject_id=req.subject_id,
            questions=questions,
            total_questions=len(questions),
        )

    async def generate_flashcards(self, user_id: str, req: FlashcardGenerateRequest) -> FlashcardGenerateResponse:
        """Generate structured flashcard study deck extracted from course chunks."""
        search_query = req.topic or "definitions terms formulas core concepts"
        search_res = await self.ingestion_service.search_similar_chunks(
            user_id=user_id,
            search_query=SemanticSearchQuery(
                query=search_query,
                subject_id=req.subject_id,
                top_k=max(req.num_cards * 2, 10),
            ),
        )

        cards: List[FlashcardItemModel] = []
        chunks = search_res.results

        if not chunks:
            cards.append(
                FlashcardItemModel(
                    id="fc_sample_1",
                    front="Gradient Descent",
                    back="An iterative first-order optimization algorithm for finding a local minimum of a differentiable loss function.",
                    category="Optimization",
                )
            )
            return FlashcardGenerateResponse(
                title=f"Flashcards: {req.topic or 'Core Concepts'}",
                subject_id=req.subject_id,
                cards=cards,
                total_cards=len(cards),
            )

        for idx, chunk in enumerate(chunks[: req.num_cards]):
            text = chunk.text_content
            lines = [l.strip() for l in text.split("\n") if l.strip()]

            # Determine front & back
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

    async def generate_summary(self, user_id: str, req: SummaryGenerateRequest) -> SummaryGenerateResponse:
        """Generate high-yield exam revision cheat sheet."""
        search_query = req.topic or "overview summary formulas exam review"
        search_res = await self.ingestion_service.search_similar_chunks(
            user_id=user_id,
            search_query=SemanticSearchQuery(
                query=search_query,
                subject_id=req.subject_id,
                top_k=8,
            ),
        )

        citations: List[CitationItemModel] = []
        key_concepts: List[str] = []
        formulas: List[str] = []

        for item in search_res.results:
            citation = CitationItemModel(
                chunk_id=item.chunk_id,
                source_id=item.source_id,
                source_name=item.source_name,
                source_type=item.source_type,
                subject_id=item.subject_id,
                page_or_section=item.page_or_section,
                snippet=item.text_content[:180] + "...",
                similarity_score=item.similarity_score,
            )
            citations.append(citation)

            # Extract concepts and formulas
            sentences = [s.strip() for s in item.text_content.split(".") if len(s.strip()) > 20]
            if sentences:
                key_concepts.append(f"{sentences[0]} [{item.source_name}]")
            if any(math_sym in item.text_content for math_sym in ["=", "+", "-", "*", "/", "theta", "alpha", "$"]):
                for line in item.text_content.split("\n"):
                    if any(sym in line for sym in ["=", "def ", "$$", "\\"]):
                        formulas.append(line.strip())

        overview = (
            f"Comprehensive syllabus synthesis compiled from {len(citations)} indexed source materials. "
            f"Focus on algorithmic foundations, mathematical formulations, and critical exam definitions."
        )

        exam_tips = [
            "Be prepared to write iterative equations and state time/space complexities on assessments.",
            "Verify all preconditions and edge cases before applying optimization theorems.",
            "Review connected lecture slides and completed assignment homework problems.",
        ]

        return SummaryGenerateResponse(
            title=f"Revision Summary: {req.topic or 'High-Yield Exam Prep'}",
            subject_id=req.subject_id,
            overview=overview,
            key_concepts=key_concepts[:6] or ["Master the core algorithmic definitions and proof properties."],
            important_formulas_or_takeaways=formulas[:4] or ["Loss update: theta = theta - alpha * gradient(J(theta))"],
            exam_tips=exam_tips,
            citations=citations,
        )
