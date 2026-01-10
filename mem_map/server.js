const http = require("http");
const fs = require("fs");
const path = require("path");

const host = process.env.HOST || "127.0.0.1";
const port = Number(process.env.PORT || "4500");
const token = process.env.MEMMAP_TOKEN || "";

const dataPath = path.join(__dirname, "data", "context-data.json");

function ensureDataFile() {
  if (!fs.existsSync(dataPath)) {
    fs.mkdirSync(path.dirname(dataPath), { recursive: true });
    const seed = {
      schema_version: 2,
      updated_at: new Date().toISOString(),
      repo: {
        name: "CDP",
        root: process.cwd(),
      },
      content: {
        nodes: [],
        edges: [],
      },
      views: [],
    };
    fs.writeFileSync(dataPath, JSON.stringify(seed, null, 2), "utf8");
  }
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (chunk) => {
      data += chunk;
      if (data.length > 5 * 1024 * 1024) {
        reject(new Error("Payload too large"));
        req.destroy();
      }
    });
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

function send(res, status, payload) {
  const body =
    typeof payload === "string" ? payload : JSON.stringify(payload, null, 2);
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(body);
}

function requireAuth(req, res) {
  if (!token) return true;
  const reqToken = req.headers["x-memmap-token"];
  if (reqToken !== token) {
    send(res, 401, { error: "Unauthorized" });
    return false;
  }
  return true;
}

ensureDataFile();

const server = http.createServer(async (req, res) => {
  const url = req.url || "/";

  if (url === "/health") {
    return send(res, 200, { ok: true });
  }

  if (!requireAuth(req, res)) return;

  if (req.method === "GET" && url === "/api/context") {
    try {
      const raw = fs.readFileSync(dataPath, "utf8");
      const data = JSON.parse(raw);
      return send(res, 200, data);
    } catch (err) {
      return send(res, 500, { error: String(err) });
    }
  }

  if (req.method === "POST" && url === "/api/context") {
    try {
      const body = await readBody(req);
      const data = JSON.parse(body || "{}");
      if (!data.schema_version) data.schema_version = 2;
      data.updated_at = new Date().toISOString();
      fs.writeFileSync(dataPath, JSON.stringify(data, null, 2), "utf8");
      return send(res, 200, { ok: true });
    } catch (err) {
      return send(res, 400, { error: String(err) });
    }
  }

  if (req.method === "POST" && url === "/api/scan") {
    return send(res, 501, { error: "Scan not implemented in CLI mode." });
  }

  return send(res, 404, { error: "Not found" });
});

server.listen(port, host, () => {
  console.log(`Memory Map server: http://${host}:${port}`);
});
