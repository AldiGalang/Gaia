import os
import sys
import subprocess
import aiohttp
import asyncio
import re
from colorama import init, Fore

init(autoreset=True)

# === AUTO-INSTALL DEPENDENSI ===
def install_dependencies():
    required_packages = ["aiohttp", "colorama"]
    
    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            print(f"{Fore.LIGHTYELLOW_EX}⚡ Installing {package}...")
            subprocess.run([sys.executable, "-m", "pip", "install", package], check=True)

install_dependencies()

# === BANNER PROGRAM ===
print(f"{Fore.LIGHTWHITE_EX}=" * 50)
print(f"{Fore.LIGHTWHITE_EX}             GAIANET - AUTO CHATBOT AI               ")
print(f"{Fore.LIGHTWHITE_EX}=" * 50)

# === DEFAULT DOMAIN TANPA INPUT USER ===
DEFAULT_DOMAIN = "optimize.gaia.domains"

print(f"{Fore.LIGHTCYAN_EX}🌍 Selected Domain: {Fore.LIGHTWHITE_EX}{DEFAULT_DOMAIN}")
print(f"{Fore.LIGHTWHITE_EX}=" * 50)

# === MEMINTA INPUT API KEY DARI USER ===
def get_api_keys():
    api_keys = []
    print(f"{Fore.LIGHTMAGENTA_EX}🔑 Enter your API Keys (one per line). Type 'DONE' when finished:")
    
    while True:
        api_key = input(f"{Fore.LIGHTWHITE_EX}> ").strip()
        if api_key.lower() == "done":
            break
        elif api_key:
            api_keys.append(api_key)
    
    if not api_keys:
        print(f"{Fore.LIGHTRED_EX}🚨 No API keys entered! Exiting program.")
        sys.exit()
    
    return api_keys

API_KEYS = get_api_keys()

# === AMBIL PERTANYAAN DARI GITHUB ===
async def fetch_questions():
    url = "https://raw.githubusercontent.com/AldiGalang/Gaia/refs/heads/main/test.txt"
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=10) as response:
                response.raise_for_status()
                content = await response.text()
                questions = [q.strip() for q in content.split("\n") if q.strip()]
                
                if not questions:
                    print(f"{Fore.LIGHTRED_EX}🚨 No questions found from the source!")
                    sys.exit()
                
                return questions
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}🚨 Failed to fetch questions: {str(e)}")
        sys.exit()

# === KELAS CHATBOT ===
class ChatBot:
    def __init__(self):
        self.api_key_index = 0

    def get_next_api_key(self):
        api_key = API_KEYS[self.api_key_index]
        self.api_key_index = (self.api_key_index + 1) % len(API_KEYS)
        return api_key

    async def send_question(self, question, max_retries=5):
        retries = 0
        while retries < max_retries:
            api_key = self.get_next_api_key()
            
            data = {
                "messages": [
                    {"role": "system", "content": "You are a helpful assistant."},
                    {"role": "user", "content": question}
                ]
            }

            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {api_key}",
            }
            
            async with aiohttp.ClientSession() as session:
                try:
                    async with session.post(f"https://{DEFAULT_DOMAIN}/v1/chat/completions", headers=headers, json=data, timeout=120) as response:
                        response.raise_for_status()
                        result = await response.json()
                        answer = result["choices"][0]["message"]["content"]
                        
                        print(f"{Fore.LIGHTGREEN_EX}💬 Answer: {Fore.LIGHTWHITE_EX}{answer}")
                        return answer
                except Exception as e:
                    retries += 1
                    print(f"{Fore.LIGHTRED_EX}🚨 Error: {Fore.LIGHTWHITE_EX}{str(e)} (Attempt {retries}/{max_retries})")
                    await asyncio.sleep(5)
        
        return None

async def main():
    bot = ChatBot()
    QUESTIONS = await fetch_questions()
    cycle = 0

    while True:
        cycle += 1
        answered, failed = 0, 0

        print(f"{Fore.LIGHTGREEN_EX}🏁 Starting session {cycle} for {len(QUESTIONS)} questions")
        print(f"{Fore.LIGHTWHITE_EX}=" * 50)

        for question in QUESTIONS:
            print(f"{Fore.LIGHTBLUE_EX}📝 Question: {Fore.LIGHTWHITE_EX}{question}")

            response = await bot.send_question(question)

            if response:
                answered += 1
            else:
                print(f"{Fore.LIGHTYELLOW_EX}😞 Failed to get an answer.")
                failed += 1
            
            await asyncio.sleep(10)  # Delay sebelum pertanyaan berikutnya

        print(f"{Fore.LIGHTBLUE_EX}🎯 Session {cycle} completed!")
        print(f"{Fore.LIGHTGREEN_EX}✅ Answered: {answered}")
        print(f"{Fore.LIGHTRED_EX}❌ Failed: {failed}")
        print(f"{Fore.LIGHTWHITE_EX}=" * 50)
        await asyncio.sleep(5)

try:
    asyncio.run(main())
except KeyboardInterrupt:
    print(f"{Fore.LIGHTRED_EX}🛑 Program interrupted by user.")

