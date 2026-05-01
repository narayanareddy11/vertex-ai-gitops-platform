"""
Automated screenshot capture for all platform services.
Run after all port-forwards are active:
    python docs/take_screenshots.py
"""
import asyncio, os, time
from playwright.async_api import async_playwright

OUT = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(OUT, exist_ok=True)

SERVICES = [
    # (name, url, wait_selector, extra_actions)
    ("01-argocd",      "http://localhost:8080",       "input[name='username']",        "login_argocd"),
    ("02-jenkins",     "http://localhost:8888",        "#header",                        None),
    ("03-vault",       "http://localhost:8200/ui",     "input[placeholder='Token']",     "login_vault"),
    ("04-grafana",     "http://localhost:3000",         "input[name='user']",             "login_grafana"),
    ("05-prometheus",  "http://localhost:9090",         ".prometheus-logo",               None),
    ("06-jaeger",      "http://localhost:16686",        ".ReactModal__Content, .App",     None),
    ("07-kiali",       "http://localhost:20001",        "#loading-kiali-spinner, .pf-c-page", None),
    ("08-sample-app",  "http://localhost:8000/docs",   "#swagger-ui",                    None),
    ("09-ml-model",    "http://localhost:8001/docs",   "#swagger-ui",                    None),
    ("10-sample-health","http://localhost:8000/health","body",                           None),
    ("11-ml-health",   "http://localhost:8001/health", "body",                           None),
]


async def take_screenshot(page, name, url, selector, action):
    print(f"  → {name}  {url}")
    try:
        await page.goto(url, timeout=15000, wait_until="domcontentloaded")
        await page.wait_for_timeout(3000)

        if action == "login_argocd":
            try:
                await page.fill("input[name='username']", "admin")
                await page.fill("input[name='password']", "admin")  # replaced by script
                await page.click("button[type='submit']")
                await page.wait_for_timeout(3000)
            except Exception:
                pass

        if action == "login_vault":
            try:
                await page.fill("input[placeholder='Token']", "root")
                await page.click("button[type='submit']")
                await page.wait_for_timeout(2000)
            except Exception:
                pass

        if action == "login_grafana":
            try:
                await page.fill("input[name='user']", "admin")
                await page.fill("input[name='password']", "admin")
                await page.click("button[type='submit']")
                await page.wait_for_timeout(2000)
            except Exception:
                pass

        path = os.path.join(OUT, f"{name}.png")
        await page.screenshot(path=path, full_page=False)
        print(f"     ✅ saved → {path}")
        return path
    except Exception as e:
        print(f"     ❌ failed: {e}")
        return None


async def main():
    print("=" * 55)
    print(" Vertex AI GitOps Platform — Screenshot Capture")
    print("=" * 55)
    paths = []
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            viewport={"width": 1440, "height": 900},
            ignore_https_errors=True,
        )
        page = await context.new_page()

        for name, url, selector, action in SERVICES:
            path = await take_screenshot(page, name, url, selector, action)
            if path:
                paths.append((name, path))

        await browser.close()

    print("\nCaptured screenshots:")
    for name, path in paths:
        print(f"  {path}")
    return paths


if __name__ == "__main__":
    asyncio.run(main())
