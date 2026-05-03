const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Use environment variable for screenshot directory (fallback optional)
const screenshotDir = process.env.SCREENSHOT_DIR || "./screenshots";

if (!fs.existsSync(screenshotDir)) {
    fs.mkdirSync(screenshotDir, { recursive: true });
}

function out(result, message) {
    console.log(`RESULT:${result}`);
    console.log(`MESSAGE:${message}`);
}

(async () => {

    // 🔐 Credentials from environment variables
    const USER = process.env.MIE_USERNAME;
    const PASS = process.env.MIE_PASSWORD;

    if (!USER || !PASS) {
        out("CONFIG_ERROR", "Missing environment variables for credentials");
        process.exit(1);
    }

    const ts = new Date().toISOString().replace(/[:.]/g, '-');
    const screenshotPath = path.join(screenshotDir, `MIE-${ts}.png`);

    let browser;
    let page;

    try {

        browser = await chromium.launch({
            headless: true,
            channel: 'msedge'
        });

        page = await browser.newPage();

        // 🌐 OPEN SITE
        try {
            await page.goto(process.env.MIE_URL || 'https://example.com/login', {
                waitUntil: 'domcontentloaded',
                timeout: 60000
            });
        } catch (err) {

            await page?.screenshot({ path: screenshotPath, fullPage: true }).catch(() => {});
            out("SITE_DOWN", err.message);

            await browser.close();
            process.exit(1);
        }

        // 🧱 CHECK LOGIN FORM
        const form = await page.$('#termsUserName');

        if (!form) {
            await page.screenshot({ path: screenshotPath, fullPage: true });
            out("UI_BROKEN", "Login form not found");

            await browser.close();
            process.exit(1);
        }

        // 🔐 FILL LOGIN
        await page.fill('#termsUserName', USER);
        await page.fill('#termsPassword', PASS);
        await page.check('#checkbox2');

        // ⏱ LOGIN + TIMEOUT HANDLING
        try {

            await Promise.all([
                page.waitForNavigation({
                    waitUntil: 'domcontentloaded',
                    timeout: 30000
                }),
                page.click('button[type="submit"]')
            ]);

        } catch (err) {

            await page.screenshot({ path: screenshotPath, fullPage: true });

            out("LOGIN_TIMEOUT", err.message);

            await browser.close();
            process.exit(1);
        }

        // 🔍 VERIFY LOGIN SUCCESS
        const loggedIn = await page
            .waitForSelector('.header-profile', { timeout: 15000 })
            .then(() => true)
            .catch(() => false);

        if (!loggedIn) {

            await page.screenshot({ path: screenshotPath, fullPage: true });

            out("LOGIN_FAILED", "Invalid credentials or login rejected");

            await browser.close();
            process.exit(1);
        }

        // ✅ SUCCESS
        out("OK", "Login successful");

        await browser.close();
        process.exit(0);

    } catch (err) {

        if (page) {
            await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => {});
        }

        out("UNKNOWN", err.message);

        if (browser) await browser.close();
        process.exit(1);
    }

})();