# ZAP by Checkmarx Scanning Report


## Summary of Alerts

| Risk Level | Number of Alerts |
| --- | --- |
| Hoch | 0 |
| Mittel | 2 |
| Gering | 2 |
| Informational | 1 |




## Insights

| Level | Grund | Site | Beschreibung | Statistic |
| --- | --- | --- | --- | --- |
| Gering | Warnung |  | ZAP errors logged - see the zap.log file for details | 4    |
| Gering | Warnung |  | ZAP warnings logged - see the zap.log file for details | 26    |
| Gering | Exceeded High | http://localhost:3000 | Percentage of responses with status code 4xx | 65 % |
| Info | Informational | http://localhost:3000 | Percentage of responses with status code 2xx | 28 % |
| Info | Informational | http://localhost:3000 | Percentage of responses with status code 3xx | 6 % |
| Info | Informational | http://localhost:3000 | Percentage of endpoints with content type application/javascript | 40 % |
| Info | Informational | http://localhost:3000 | Percentage of endpoints with content type text/css | 3 % |
| Info | Informational | http://localhost:3000 | Percentage of endpoints with content type text/html | 56 % |
| Info | Informational | http://localhost:3000 | Percentage of endpoints with method GET | 100 % |
| Info | Informational | http://localhost:3000 | Count of total endpoints | 30    |
| Info | Exceeded Low | http://localhost:3000 | Percentage of slow responses | 12 % |




## Warnungen

| Name | Risk Level | Number of Instances |
| --- | --- | --- |
| Content Security Policy (CSP) Header Not Set | Mittel | Systemic |
| Missing Anti-clickjacking Header | Mittel | Systemic |
| Server Leaks Information via "X-Powered-By" HTTP Response Header Field(s) | Gering | Systemic |
| X-Content-Type-Options Header Missing | Gering | Systemic |
| Information Disclosure - Suspicious Comments | Informational | 15 |




## Alert Detail



### [ Content Security Policy (CSP) Header Not Set ](https://www.zaproxy.org/docs/alerts/10038/)



##### Mittel (Hoch)

### Beschreibung

Content Security Policy (CSP) is an added layer of security that helps to detect and mitigate certain types of attacks, including Cross Site Scripting (XSS) and data injection attacks. These attacks are used for everything from data theft to site defacement or distribution of malware. CSP provides a set of standard HTTP headers that allow website owners to declare approved sources of content that browsers should be allowed to load on that page — covered types are JavaScript, CSS, HTML frames, fonts, images and embeddable objects such as Java applets, ActiveX, audio and video files.

* URL: http://localhost:3000/
  * Node Name: `http://localhost:3000/`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/jobs
  * Node Name: `http://localhost:3000/jobs`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/robots.txt
  * Node Name: `http://localhost:3000/robots.txt`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/sitemap.xml
  * Node Name: `http://localhost:3000/sitemap.xml`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/suche
  * Node Name: `http://localhost:3000/suche`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``

Instances: Systemic


### Solution

Ensure that your web server, application server, load balancer, etc. is configured to set the Content-Security-Policy header.

### Reference


* [ https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP ](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP)
* [ https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html ](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html)
* [ https://www.w3.org/TR/CSP/ ](https://www.w3.org/TR/CSP/)
* [ https://w3c.github.io/webappsec-csp/ ](https://w3c.github.io/webappsec-csp/)
* [ https://web.dev/articles/csp ](https://web.dev/articles/csp)
* [ https://caniuse.com/#feat=contentsecuritypolicy ](https://caniuse.com/#feat=contentsecuritypolicy)
* [ https://content-security-policy.com/ ](https://content-security-policy.com/)


#### CWE Id: [ 693 ](https://cwe.mitre.org/data/definitions/693.html)


#### WASC Id: 15

#### Source ID: 3

### [ Missing Anti-clickjacking Header ](https://www.zaproxy.org/docs/alerts/10020/)



##### Mittel (Mittel)

### Beschreibung

The response does not protect against 'ClickJacking' attacks. It should include either Content-Security-Policy with 'frame-ancestors' directive or X-Frame-Options.

* URL: http://localhost:3000/
  * Node Name: `http://localhost:3000/`
  * Methode: `GET`
  * Parameter: `x-frame-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/%3Fsearch=ZAP
  * Node Name: `http://localhost:3000/ (search)`
  * Methode: `GET`
  * Parameter: `x-frame-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/accessibility
  * Node Name: `http://localhost:3000/accessibility`
  * Methode: `GET`
  * Parameter: `x-frame-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/jobs
  * Node Name: `http://localhost:3000/jobs`
  * Methode: `GET`
  * Parameter: `x-frame-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/suche
  * Node Name: `http://localhost:3000/suche`
  * Methode: `GET`
  * Parameter: `x-frame-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: ``

Instances: Systemic


### Solution

Modern Web browsers support the Content-Security-Policy and X-Frame-Options HTTP headers. Ensure one of them is set on all web pages returned by your site/app.
If you expect the page to be framed only by pages on your server (e.g. it's part of a FRAMESET) then you'll want to use SAMEORIGIN, otherwise if you never expect the page to be framed, you should use DENY. Alternatively consider implementing Content Security Policy's "frame-ancestors" directive.

### Reference


* [ https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/X-Frame-Options ](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/X-Frame-Options)


#### CWE Id: [ 1021 ](https://cwe.mitre.org/data/definitions/1021.html)


#### WASC Id: 15

#### Source ID: 3

### [ Server Leaks Information via "X-Powered-By" HTTP Response Header Field(s) ](https://www.zaproxy.org/docs/alerts/10037/)



##### Gering (Mittel)

### Beschreibung

The web/application server is leaking information via one or more "X-Powered-By" HTTP response headers. Access to such information may facilitate attackers identifying other frameworks/components your web application is reliant upon and the vulnerabilities such components may be subject to.

* URL: http://localhost:3000/
  * Node Name: `http://localhost:3000/`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `X-Powered-By: Next.js`
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/jobs
  * Node Name: `http://localhost:3000/jobs`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `X-Powered-By: Next.js`
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/robots.txt
  * Node Name: `http://localhost:3000/robots.txt`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `X-Powered-By: Next.js`
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/sitemap.xml
  * Node Name: `http://localhost:3000/sitemap.xml`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `X-Powered-By: Next.js`
  * Zusätzliche Informationen:: ``
* URL: http://localhost:3000/suche
  * Node Name: `http://localhost:3000/suche`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `X-Powered-By: Next.js`
  * Zusätzliche Informationen:: ``

Instances: Systemic


### Solution

Ensure that your web server, application server, load balancer, etc. is configured to suppress "X-Powered-By" headers.

### Reference


* [ https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/08-Fingerprint_Web_Application_Framework ](https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/08-Fingerprint_Web_Application_Framework)
* [ https://www.troyhunt.com/shhh-dont-let-your-response-headers/ ](https://www.troyhunt.com/shhh-dont-let-your-response-headers/)


#### CWE Id: [ 497 ](https://cwe.mitre.org/data/definitions/497.html)


#### WASC Id: 13

#### Source ID: 3

### [ X-Content-Type-Options Header Missing ](https://www.zaproxy.org/docs/alerts/10021/)



##### Gering (Mittel)

### Beschreibung

The Anti-MIME-Sniffing header X-Content-Type-Options was not set to 'nosniff'. This allows older versions of Internet Explorer and Chrome to perform MIME-sniffing on the response body, potentially causing the response body to be interpreted and displayed as a content type other than the declared content type. Current (early 2014) and legacy versions of Firefox will use the declared content type (if one is set), rather than performing MIME-sniffing.

* URL: http://localhost:3000/
  * Node Name: `http://localhost:3000/`
  * Methode: `GET`
  * Parameter: `x-content-type-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: `This issue still applies to error type pages (401, 403, 500, etc.) as those pages are often still affected by injection issues, in which case there is still concern for browsers sniffing pages away from their actual content type.
At "High" threshold this scan rule will not alert on client or server error responses.`
* URL: http://localhost:3000/_next/static/chunks/app-pages-internals.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app-pages-internals.js`
  * Methode: `GET`
  * Parameter: `x-content-type-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: `This issue still applies to error type pages (401, 403, 500, etc.) as those pages are often still affected by injection issues, in which case there is still concern for browsers sniffing pages away from their actual content type.
At "High" threshold this scan rule will not alert on client or server error responses.`
* URL: http://localhost:3000/_next/static/chunks/app/layout.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/layout.js`
  * Methode: `GET`
  * Parameter: `x-content-type-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: `This issue still applies to error type pages (401, 403, 500, etc.) as those pages are often still affected by injection issues, in which case there is still concern for browsers sniffing pages away from their actual content type.
At "High" threshold this scan rule will not alert on client or server error responses.`
* URL: http://localhost:3000/_next/static/chunks/polyfills.js
  * Node Name: `http://localhost:3000/_next/static/chunks/polyfills.js`
  * Methode: `GET`
  * Parameter: `x-content-type-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: `This issue still applies to error type pages (401, 403, 500, etc.) as those pages are often still affected by injection issues, in which case there is still concern for browsers sniffing pages away from their actual content type.
At "High" threshold this scan rule will not alert on client or server error responses.`
* URL: http://localhost:3000/_next/static/css/app/layout.css%3Fv=1780342177136
  * Node Name: `http://localhost:3000/_next/static/css/app/layout.css (v)`
  * Methode: `GET`
  * Parameter: `x-content-type-options`
  * Angriff: ``
  * Evidence: ``
  * Zusätzliche Informationen:: `This issue still applies to error type pages (401, 403, 500, etc.) as those pages are often still affected by injection issues, in which case there is still concern for browsers sniffing pages away from their actual content type.
At "High" threshold this scan rule will not alert on client or server error responses.`

Instances: Systemic


### Solution

Ensure that the application/web server sets the Content-Type header appropriately, and that it sets the X-Content-Type-Options header to 'nosniff' for all web pages.
If possible, ensure that the end user uses a standards-compliant and modern web browser that does not perform MIME-sniffing at all, or that can be directed by the web application/web server to not perform MIME-sniffing.

### Reference


* [ https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/compatibility/gg622941(v=vs.85) ](https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/compatibility/gg622941(v=vs.85))
* [ https://owasp.org/www-community/Security_Headers ](https://owasp.org/www-community/Security_Headers)


#### CWE Id: [ 693 ](https://cwe.mitre.org/data/definitions/693.html)


#### WASC Id: 15

#### Source ID: 3

### [ Information Disclosure - Suspicious Comments ](https://www.zaproxy.org/docs/alerts/10027/)



##### Informational (Mittel)

### Beschreibung

The response appears to contain suspicious comments which may help an attacker.

* URL: http://localhost:3000/_next/static/chunks/app-pages-internals.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app-pages-internals.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app-pages-internals.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app-pages-internals.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ponents%5C%5Crender-from-template-context.js`
  * Zusätzliche Informationen:: `The following pattern was used: \bFROM\b and was detected 2 times, the first in likely comment: "/*!*****************************************************************************************************************************", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/(auth&29/forgot-password/page.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/(auth)/forgot-password/page.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/(auth&29/login/page.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/(auth)/login/page.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/(auth&29/register/azubi/page.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/(auth)/register/azubi/page.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/(auth&29/register/betrieb/page.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/(auth)/register/betrieb/page.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/accessibility/page.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/accessibility/page.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/hilfe/page.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/hilfe/page.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/layout.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/layout.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/app/unternehmen/page.js
  * Node Name: `http://localhost:3000/_next/static/chunks/app/unternehmen/page.js`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/main-app.js%3Fv=1780342177136
  * Node Name: `http://localhost:3000/_next/static/chunks/main-app.js (v)`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `ad the output file, select a different devtool`
  * Zusätzliche Informationen:: `The following pattern was used: \bSELECT\b and was detected in likely comment: "/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable out", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/main-app.js%3Fv=1780342177136
  * Node Name: `http://localhost:3000/_next/static/chunks/main-app.js (v)`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `reducer/create-href-from-url.js ***!
  \****`
  * Zusätzliche Informationen:: `The following pattern was used: \bFROM\b and was detected 2 times, the first in likely comment: "/*!*****************************************************************************************!*\
  !*** ./node_modules/next/dist/", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/webpack.js%3Fv=1780342179368
  * Node Name: `http://localhost:3000/_next/static/chunks/webpack.js (v)`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `/** @type {TODO} */`
  * Zusätzliche Informationen:: `The following pattern was used: \bTODO\b and was detected in likely comment: "/** @type {TODO} */", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/webpack.js%3Fv=1780342179175
  * Node Name: `http://localhost:3000/_next/static/chunks/webpack.js (v)`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `// inherit from previous dispose ca`
  * Zusätzliche Informationen:: `The following pattern was used: \bFROM\b and was detected 5 times, the first in likely comment: "// inherit from previous dispose call", see evidence field for the suspicious comment/snippet.`
* URL: http://localhost:3000/_next/static/chunks/webpack.js%3Fv=1780342179175
  * Node Name: `http://localhost:3000/_next/static/chunks/webpack.js (v)`
  * Methode: `GET`
  * Parameter: ``
  * Angriff: ``
  * Evidence: `t useful stacktrace later`
  * Zusätzliche Informationen:: `The following pattern was used: \bLATER\b and was detected 3 times, the first in likely comment: "// create error before stack unwound to get useful stacktrace later", see evidence field for the suspicious comment/snippet.`


Instances: 15

### Solution

Remove all comments that return information that may help an attacker and fix any underlying problems they refer to.

### Reference



#### CWE Id: [ 615 ](https://cwe.mitre.org/data/definitions/615.html)


#### WASC Id: 13

#### Source ID: 3


