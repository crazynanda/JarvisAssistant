"""
File Analysis Module for J.A.R.V.I.S
Handles PDF extraction and image OCR
"""

import io
import logging
from typing import Optional
from PyPDF2 import PdfReader
from PIL import Image
import pytesseract

logger = logging.getLogger(__name__)

class FileAnalyzer:
    """Analyzes files and extracts text content"""
    
    def __init__(self):
        """Initialize file analyzer"""
        self.supported_image_formats = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.gif']
        self.supported_pdf_formats = ['.pdf']
    
    def extract_pdf_text(self, file_content: bytes) -> str:
        """
        Extract text from PDF file
        
        Args:
            file_content: PDF file bytes
            
        Returns:
            Extracted text
        """
        try:
            # Create PDF reader from bytes
            pdf_file = io.BytesIO(file_content)
            pdf_reader = PdfReader(pdf_file)
            
            # Extract text from all pages
            text_parts = []
            for page_num, page in enumerate(pdf_reader.pages, 1):
                try:
                    text = page.extract_text()
                    if text.strip():
                        text_parts.append(f"[Page {page_num}]\n{text}")
                except Exception as e:
                    logger.warning(f"Error extracting page {page_num}: {e}")
            
            full_text = "\n\n".join(text_parts)
            
            if not full_text.strip():
                return "No text could be extracted from the PDF."
            
            logger.info(f"Extracted {len(full_text)} characters from PDF ({len(pdf_reader.pages)} pages)")
            return full_text
            
        except Exception as e:
            logger.error(f"Error extracting PDF text: {e}")
            raise ValueError(f"Failed to extract PDF text: {str(e)}")
    
    def extract_image_text(self, file_content: bytes) -> str:
        """
        Extract text from image using OCR
        
        Args:
            file_content: Image file bytes
            
        Returns:
            Extracted text
        """
        try:
            # Open image from bytes
            image = Image.open(io.BytesIO(file_content))
            
            # Perform OCR
            text = pytesseract.image_to_string(image)
            
            if not text.strip():
                return "No text could be extracted from the image."
            
            logger.info(f"Extracted {len(text)} characters from image via OCR")
            return text.strip()
            
        except Exception as e:
            logger.error(f"Error extracting image text: {e}")
            
            # Check if tesseract is installed
            if "tesseract is not installed" in str(e).lower():
                raise ValueError(
                    "Tesseract OCR is not installed. "
                    "Please install it: https://github.com/tesseract-ocr/tesseract"
                )
            
            raise ValueError(f"Failed to extract image text: {str(e)}")
    
    def analyze_file(self, filename: str, file_content: bytes) -> dict:
        """
        Analyze file and extract content
        
        Args:
            filename: Original filename
            file_content: File bytes
            
        Returns:
            Dictionary with file_type and extracted_text
        """
        # Determine file type
        filename_lower = filename.lower()
        
        if any(filename_lower.endswith(ext) for ext in self.supported_pdf_formats):
            file_type = "pdf"
            extracted_text = self.extract_pdf_text(file_content)
        elif any(filename_lower.endswith(ext) for ext in self.supported_image_formats):
            file_type = "image"
            extracted_text = self.extract_image_text(file_content)
        else:
            raise ValueError(
                f"Unsupported file type. Supported: PDF, "
                f"Images ({', '.join(self.supported_image_formats)})"
            )
        
        return {
            "file_type": file_type,
            "filename": filename,
            "extracted_text": extracted_text,
            "text_length": len(extracted_text)
        }

# Global analyzer instance
analyzer = None

def get_analyzer() -> FileAnalyzer:
    """Get or create global analyzer instance"""
    global analyzer
    if analyzer is None:
        analyzer = FileAnalyzer()
    return analyzer
