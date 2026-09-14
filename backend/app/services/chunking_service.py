import re
from typing import Any, Dict, List


class ChunkingService:
    """Recursive character and sentence-aware chunking engine for document and note ingestion."""

    DEFAULT_CHUNK_SIZE = 500  # characters
    DEFAULT_CHUNK_OVERLAP = 100  # characters

    @classmethod
    def chunk_sections(
        cls,
        sections: List[Dict[str, Any]],
        chunk_size: int = DEFAULT_CHUNK_SIZE,
        chunk_overlap: int = DEFAULT_CHUNK_OVERLAP,
    ) -> List[Dict[str, Any]]:
        """Split a list of extracted document sections into overlapping chunks.
        Each input section is a dict: {'page_or_section': str, 'text': str}
        Returns: List of dicts with keys: 'chunk_index', 'page_or_section', 'text_content', 'token_count'
        """
        all_chunks: List[Dict[str, Any]] = []
        global_chunk_index = 0

        for sec in sections:
            section_name = sec.get("page_or_section", "General")
            raw_text = sec.get("text", "").strip()
            if not raw_text:
                continue

            section_chunks = cls.split_text_recursively(
                text=raw_text,
                chunk_size=chunk_size,
                chunk_overlap=chunk_overlap,
            )

            for chunk_text in section_chunks:
                clean_chunk = chunk_text.strip()
                if not clean_chunk:
                    continue

                token_count = cls.estimate_tokens(clean_chunk)
                all_chunks.append({
                    "chunk_index": global_chunk_index,
                    "page_or_section": section_name,
                    "text_content": clean_chunk,
                    "token_count": token_count,
                })
                global_chunk_index += 1

        return all_chunks

    @classmethod
    def split_text_recursively(
        cls,
        text: str,
        chunk_size: int,
        chunk_overlap: int,
    ) -> List[str]:
        """Recursively split text using double newlines, single newlines, sentence ends, and spaces."""
        if len(text) <= chunk_size:
            return [text]

        separators = ["\n\n", "\n", ". ", "! ", "? ", "; ", ", ", " "]
        return cls._split_with_separators(text, separators, chunk_size, chunk_overlap)

    @classmethod
    def _split_with_separators(
        cls,
        text: str,
        separators: List[str],
        chunk_size: int,
        chunk_overlap: int,
    ) -> List[str]:
        if not separators:
            # Fallback: slice directly by character length
            chunks = []
            start = 0
            while start < len(text):
                end = min(start + chunk_size, len(text))
                chunks.append(text[start:end])
                start += max(1, chunk_size - chunk_overlap)
            return chunks

        sep = separators[0]
        remaining_seps = separators[1:]

        splits = text.split(sep)
        chunks: List[str] = []
        current_chunk_parts: List[str] = []
        current_length = 0

        for part in splits:
            part_len = len(part) + (len(sep) if current_chunk_parts else 0)

            if current_length + part_len <= chunk_size:
                current_chunk_parts.append(part)
                current_length += part_len
            else:
                if current_chunk_parts:
                    combined = sep.join(current_chunk_parts)
                    chunks.append(combined)

                    # Build overlap from trailing parts
                    overlap_parts: List[str] = []
                    overlap_len = 0
                    for p in reversed(current_chunk_parts):
                        if overlap_len + len(p) <= chunk_overlap:
                            overlap_parts.insert(0, p)
                            overlap_len += len(p)
                        else:
                            break
                    current_chunk_parts = overlap_parts
                    current_length = sum(len(p) for p in current_chunk_parts) + (len(sep) * max(0, len(current_chunk_parts) - 1))

                # If single part is larger than chunk_size, recurse with finer separator
                if len(part) > chunk_size:
                    sub_chunks = cls._split_with_separators(part, remaining_seps, chunk_size, chunk_overlap)
                    chunks.extend(sub_chunks)
                    current_chunk_parts = []
                    current_length = 0
                else:
                    current_chunk_parts.append(part)
                    current_length += len(part)

        if current_chunk_parts:
            combined = sep.join(current_chunk_parts)
            if combined not in chunks:
                chunks.append(combined)

        return chunks

    @staticmethod
    def estimate_tokens(text: str) -> int:
        """Estimate token count based on whitespace word count + character ratio."""
        words = len(re.findall(r"\w+", text))
        char_estimate = len(text) // 4
        return max(1, max(words, char_estimate))
