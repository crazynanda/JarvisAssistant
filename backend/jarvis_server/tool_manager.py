"""
Tool Manager for J.A.R.V.I.S
Provides web search, weather, and system status tools with intent detection
"""

import requests
from bs4 import BeautifulSoup
import bleach
import os
import logging
from typing import Dict, List, Optional
import random
from datetime import datetime

logger = logging.getLogger(__name__)

class ToolManager:
    """Manages external tools and services for J.A.R.V.I.S"""
    
    def __init__(self):
        """Initialize tool manager"""
        self.openweather_api_key = os.getenv("OPENWEATHER_API_KEY")
        
        # Intent keywords for tool detection
        self.intent_keywords = {
            'web_search': [
                'search', 'find', 'look up', 'google', 'what is', 'who is',
                'tell me about', 'information about', 'learn about'
            ],
            'weather': [
                'weather', 'temperature', 'forecast', 'rain', 'sunny',
                'climate', 'hot', 'cold', 'degrees'
            ],
            'system_status': [
                'system status', 'device status', 'system info', 'diagnostics',
                'check system', 'system health', 'status report'
            ]
        }
    
    def sanitize_text(self, text: str) -> str:
        """
        Sanitize text to prevent script injection and malicious content
        
        Args:
            text: Raw text to sanitize
            
        Returns:
            Sanitized text
        """
        if not text:
            return ""
        
        # Remove all HTML tags and scripts
        cleaned = bleach.clean(
            text,
            tags=[],  # No tags allowed
            strip=True,
            strip_comments=True
        )
        
        # Remove any remaining script-like content
        cleaned = cleaned.replace('<script', '').replace('</script>', '')
        cleaned = cleaned.replace('javascript:', '').replace('eval(', '')
        
        return cleaned.strip()
    
    def detect_intent(self, user_input: str) -> Optional[str]:
        """
        Detect user intent from input
        
        Args:
            user_input: User's input text
            
        Returns:
            Detected tool name or None
        """
        user_input_lower = user_input.lower()
        
        # Check each intent category
        for tool_name, keywords in self.intent_keywords.items():
            for keyword in keywords:
                if keyword in user_input_lower:
                    logger.info(f"Detected intent: {tool_name} (keyword: {keyword})")
                    return tool_name
        
        return None
    
    def web_search(self, query: str) -> Dict:
        """
        Perform web search and return top 3 results
        
        Args:
            query: Search query
            
        Returns:
            Dictionary with search results
        """
        try:
            # Sanitize query
            query = self.sanitize_text(query)
            
            if not query:
                return {
                    'success': False,
                    'error': 'Empty search query'
                }
            
            logger.info(f"Performing web search: {query}")
            
            # Use DuckDuckGo HTML (no API key required)
            search_url = f"https://html.duckduckgo.com/html/?q={requests.utils.quote(query)}"
            
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            response = requests.get(search_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            # Parse HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extract search results
            results = []
            result_divs = soup.find_all('div', class_='result', limit=3)
            
            for div in result_divs:
                try:
                    # Get title
                    title_elem = div.find('a', class_='result__a')
                    title = self.sanitize_text(title_elem.get_text()) if title_elem else "No title"
                    
                    # Get URL
                    url = title_elem.get('href', '') if title_elem else ''
                    
                    # Get snippet
                    snippet_elem = div.find('a', class_='result__snippet')
                    snippet = self.sanitize_text(snippet_elem.get_text()) if snippet_elem else ""
                    
                    if title and url:
                        results.append({
                            'title': title,
                            'url': url,
                            'snippet': snippet
                        })
                except Exception as e:
                    logger.warning(f"Error parsing search result: {e}")
                    continue
            
            if not results:
                return {
                    'success': False,
                    'error': 'No search results found'
                }
            
            logger.info(f"Found {len(results)} search results")
            
            return {
                'success': True,
                'query': query,
                'results': results,
                'count': len(results)
            }
            
        except requests.Timeout:
            logger.error("Web search timed out")
            return {
                'success': False,
                'error': 'Search request timed out'
            }
        except Exception as e:
            logger.error(f"Web search error: {e}")
            return {
                'success': False,
                'error': f'Search failed: {str(e)}'
            }
    
    def get_weather(self, city: str) -> Dict:
        """
        Get weather information for a city
        
        Args:
            city: City name
            
        Returns:
            Dictionary with weather data
        """
        try:
            # Sanitize city name
            city = self.sanitize_text(city)
            
            if not city:
                return {
                    'success': False,
                    'error': 'Empty city name'
                }
            
            # Check if API key is configured
            if not self.openweather_api_key:
                logger.warning("OpenWeatherMap API key not configured")
                # Return mock data for demonstration
                return self._get_mock_weather(city)
            
            logger.info(f"Fetching weather for: {city}")
            
            # Call OpenWeatherMap API
            base_url = "http://api.openweathermap.org/data/2.5/weather"
            params = {
                'q': city,
                'appid': self.openweather_api_key,
                'units': 'metric'  # Celsius
            }
            
            response = requests.get(base_url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Extract relevant information
            weather_info = {
                'success': True,
                'city': data['name'],
                'country': data['sys']['country'],
                'temperature': round(data['main']['temp'], 1),
                'feels_like': round(data['main']['feels_like'], 1),
                'description': data['weather'][0]['description'],
                'humidity': data['main']['humidity'],
                'wind_speed': data['wind']['speed'],
                'pressure': data['main']['pressure']
            }
            
            logger.info(f"Weather data retrieved for {city}")
            return weather_info
            
        except requests.Timeout:
            logger.error("Weather API request timed out")
            return {
                'success': False,
                'error': 'Weather request timed out'
            }
        except requests.HTTPError as e:
            if e.response.status_code == 404:
                return {
                    'success': False,
                    'error': f'City "{city}" not found'
                }
            return {
                'success': False,
                'error': f'Weather API error: {e.response.status_code}'
            }
        except Exception as e:
            logger.error(f"Weather error: {e}")
            return {
                'success': False,
                'error': f'Failed to get weather: {str(e)}'
            }
    
    def _get_mock_weather(self, city: str) -> Dict:
        """Generate mock weather data when API key not configured"""
        return {
            'success': True,
            'city': city,
            'country': 'XX',
            'temperature': random.randint(15, 30),
            'feels_like': random.randint(15, 30),
            'description': random.choice(['clear sky', 'partly cloudy', 'light rain']),
            'humidity': random.randint(40, 80),
            'wind_speed': round(random.uniform(2, 10), 1),
            'pressure': random.randint(1000, 1020),
            'note': 'Mock data - OpenWeatherMap API key not configured'
        }
    
    def get_system_status(self) -> Dict:
        """
        Get system status information (dummy device data)
        
        Returns:
            Dictionary with system status
        """
        try:
            logger.info("Fetching system status")
            
            # Generate dummy device data
            status = {
                'success': True,
                'timestamp': datetime.now().isoformat(),
                'devices': {
                    'main_computer': {
                        'status': 'online',
                        'cpu_usage': f"{random.randint(20, 60)}%",
                        'memory_usage': f"{random.randint(40, 70)}%",
                        'temperature': f"{random.randint(35, 55)}°C"
                    },
                    'security_system': {
                        'status': 'armed',
                        'cameras': '12/12 active',
                        'sensors': '24/24 operational'
                    },
                    'climate_control': {
                        'status': 'auto',
                        'temperature': f"{random.randint(20, 24)}°C",
                        'humidity': f"{random.randint(40, 60)}%"
                    },
                    'power_systems': {
                        'status': 'normal',
                        'grid_power': 'connected',
                        'backup_battery': f"{random.randint(85, 100)}%"
                    },
                    'network': {
                        'status': 'connected',
                        'bandwidth': f"{random.randint(500, 1000)} Mbps",
                        'latency': f"{random.randint(5, 20)} ms"
                    }
                },
                'overall_status': 'All systems operational'
            }
            
            logger.info("System status retrieved")
            return status
            
        except Exception as e:
            logger.error(f"System status error: {e}")
            return {
                'success': False,
                'error': f'Failed to get system status: {str(e)}'
            }
    
    def execute_tool(self, tool_name: str, user_input: str) -> Optional[Dict]:
        """
        Execute a tool based on detected intent
        
        Args:
            tool_name: Name of tool to execute
            user_input: User's input text
            
        Returns:
            Tool execution result or None
        """
        try:
            if tool_name == 'web_search':
                # Extract search query from input
                query = self._extract_search_query(user_input)
                return self.web_search(query)
            
            elif tool_name == 'weather':
                # Extract city from input
                city = self._extract_city(user_input)
                return self.get_weather(city)
            
            elif tool_name == 'system_status':
                return self.get_system_status()
            
            else:
                logger.warning(f"Unknown tool: {tool_name}")
                return None
                
        except Exception as e:
            logger.error(f"Tool execution error: {e}")
            return {
                'success': False,
                'error': f'Tool execution failed: {str(e)}'
            }
    
    def _extract_search_query(self, user_input: str) -> str:
        """Extract search query from user input"""
        # Remove common search prefixes
        query = user_input.lower()
        prefixes = ['search for', 'search', 'find', 'look up', 'google', 
                   'what is', 'who is', 'tell me about', 'information about']
        
        for prefix in prefixes:
            if query.startswith(prefix):
                query = query[len(prefix):].strip()
                break
        
        return query or user_input
    
    def _extract_city(self, user_input: str) -> str:
        """Extract city name from user input"""
        # Remove common weather prefixes
        text = user_input.lower()
        prefixes = ['weather in', 'weather for', 'temperature in', 
                   'forecast for', 'how is the weather in']
        
        for prefix in prefixes:
            if prefix in text:
                text = text.split(prefix, 1)[1].strip()
                break
        
        # Remove trailing question marks and periods
        text = text.rstrip('?.!')
        
        return text or user_input

# Global tool manager instance
tool_manager = None

def get_tool_manager() -> ToolManager:
    """Get or create global tool manager instance"""
    global tool_manager
    if tool_manager is None:
        tool_manager = ToolManager()
    return tool_manager
