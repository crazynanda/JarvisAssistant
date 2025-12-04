"""
Post-processing pipeline for J.A.R.V.I.S responses.
Includes SuggestionManager for proactive tips and HumorFilter for personality.
"""

import random
import logging
from typing import List, Dict, Optional
from openai import OpenAI

logger = logging.getLogger(__name__)

class HumorFilter:
    """
    Adds a touch of wit to J.A.R.V.I.S responses.
    20% chance to append a witty line from a curated list.
    """
    
    def __init__(self, chance: float = 0.2):
        self.chance = chance
        self.witty_lines = [
            "I believe I've calibrated the wit settings to your liking, sir.",
            "Just another day in paradise, isn't it?",
            "I am merely a humble digital butler, after all.",
            "Shall I also prepare the suit? Joking, of course.",
            "My processors are positively glowing with anticipation.",
            "A fascinating choice, if I may say so.",
            "I'll file that under 'Things I didn't expect today'.",
            "Efficiency is my middle name. Well, technically I don't have one.",
            "Always a pleasure to serve.",
            "I'm running diagnostics on your sense of humor. Results are... inconclusive.",
            "At your service, as always.",
            "I could do this all day. And I do.",
            "Processing complete. And with style, I might add."
        ]

    def apply(self, response_text: str) -> str:
        """
        Potentially append a witty line to the response.
        """
        if random.random() < self.chance:
            # Don't append if the response is already very short or very long
            if 10 < len(response_text) < 500:
                witty_remark = random.choice(self.witty_lines)
                logger.info("Humor module triggered")
                return f"{response_text}\n\n{witty_remark}"
        return response_text


class SuggestionManager:
    """
    Analyzes conversation context to provide helpful next-step suggestions.
    """
    
    def __init__(self, client: Optional[OpenAI]):
        self.client = client
        self.system_prompt = """
        Analyze the conversation history and provide a SINGLE, SHORT (max 10 words) next-step suggestion or tip for the user.
        The suggestion should be proactive and helpful.
        If no obvious next step exists, reply exactly "NONE".
        Do not be chatty. Just the suggestion.
        Example: "Shall I schedule that for you?" or "Would you like to send an email?"
        """

    def get_suggestion(self, recent_messages: List[Dict], context_summary: str) -> Optional[str]:
        """
        Generate a suggestion based on recent messages and memory context.
        """
        if not self.client:
            return None

        try:
            # Prepare messages for the suggestion engine
            messages = [
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": f"Context Summary: {context_summary}\n\nRecent Messages:\n{str(recent_messages[-5:])}"}
            ]

            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                max_tokens=30,
                temperature=0.5,
            )

            suggestion = response.choices[0].message.content.strip()
            
            if suggestion == "NONE" or not suggestion:
                return None
            
            logger.info(f"Generated suggestion: {suggestion}")
            return suggestion

        except Exception as e:
            logger.warning(f"Error generating suggestion: {e}")
            return None

    def apply(self, response_text: str, recent_messages: List[Dict], context_summary: str) -> str:
        """
        Generate and append a suggestion to the response.
        """
        suggestion = self.get_suggestion(recent_messages, context_summary)
        if suggestion:
            return f"{response_text}\n\nTip: {suggestion}"
        return response_text
