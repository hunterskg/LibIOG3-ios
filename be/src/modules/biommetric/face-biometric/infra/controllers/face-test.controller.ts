import {
  Body,
  Controller,
  Get,
  Header,
  Post,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { FaceGrpcAdapter } from '../grpc/adapters/face-grpc.adapter';

interface UploadedFile {
  buffer: Buffer;
  originalname?: string;
  mimetype?: string;
  size?: number;
}

function computeMatchConfidence(similarity: number): number {
  if (similarity <= 0.2) {
    return Math.max(0, Number(((similarity / 0.2) * 20.0).toFixed(1)));
  }
  if (similarity < 0.45) {
    return Number((20.0 + ((similarity - 0.2) / 0.25) * 50.0).toFixed(1));
  }
  if (similarity < 0.65) {
    return Number((70.0 + ((similarity - 0.45) / 0.2) * 25.0).toFixed(1));
  }
  return Number(
    (95.0 + Math.min(4.9, ((similarity - 0.65) / 0.2) * 4.9)).toFixed(1),
  );
}

const HTML_PAGE = `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Face Comparison Test (NestJS & Python gRPC)</title>
  <style>
    :root { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; }
    body { max-width: 900px; margin: 30px auto; padding: 0 20px; }
    h1 { font-size: 24px; font-weight: 700; margin-bottom: 6px; }
    .badge { display: inline-block; background: #0284c7; color: white; padding: 2px 8px; border-radius: 4px; font-size: 12px; margin-left: 8px; }
    p.sub { color: #94a3b8; font-size: 14px; margin-top: 0; margin-bottom: 24px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 18px; }
    .card h3 { margin: 0 0 12px 0; font-size: 16px; color: #e2e8f0; }
    .dropzone { border: 2px dashed #475569; border-radius: 8px; padding: 20px; text-align: center; cursor: pointer; background: #0f172a80; }
    .dropzone:hover { border-color: #38bdf8; }
    input[type="file"] { display: none; }
    img.preview { max-width: 100%; max-height: 220px; object-fit: contain; margin-top: 10px; border-radius: 6px; display: none; }
    .controls { margin-top: 20px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
    label { font-size: 14px; color: #cbd5e1; }
    input[type="number"] { background: #1e293b; border: 1px solid #475569; color: #f8fafc; padding: 8px 12px; border-radius: 6px; width: 75px; }
    .preset-btn { background: #334155; color: #cbd5e1; border: 1px solid #475569; padding: 6px 12px; font-size: 12px; border-radius: 6px; cursor: pointer; }
    .preset-btn:hover { background: #475569; }
    button.submit-btn { background: #0284c7; color: white; border: none; padding: 10px 24px; font-size: 15px; font-weight: 600; border-radius: 8px; cursor: pointer; transition: 0.2s; margin-left: auto; }
    button.submit-btn:hover { background: #0369a1; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .result { margin-top: 24px; padding: 20px; border-radius: 10px; display: none; }
    .result.matched { background: #064e3b; border: 1px solid #059669; }
    .result.unmatched { background: #7f1d1d; border: 1px solid #dc2626; }
    .result.error { background: #78350f; border: 1px solid #d97706; }
    .score { font-size: 26px; font-weight: 800; margin: 4px 0; }
    .liveness-box { display: flex; gap: 16px; margin: 12px 0; font-size: 13px; }
    .liveness-item { background: #0f172a60; padding: 8px 12px; border-radius: 6px; flex: 1; }
    .expl-box { margin-top: 10px; font-size: 13px; color: #cbd5e1; background: #1e293b; padding: 10px; border-radius: 6px; border-left: 4px solid #38bdf8; }
    pre { background: #0b1120; padding: 12px; border-radius: 6px; overflow-x: auto; font-size: 12px; }
  </style>
</head>
<body>
  <h1>Kiểm tra nhận diện khuôn mặt <span class="badge">NestJS &times; gRPC Python</span></h1>
  <p class="sub">Giao diện kiểm tra tính tương thích giữa NestJS Backend và Python Face gRPC (DetectFaces &bull; ExtractEmbedding &bull; VerifyFace &bull; CheckLiveness).</p>

  <form id="compareForm">
    <div class="grid">
      <div class="card">
        <h3>Ảnh 1 (Reference)</h3>
        <div class="dropzone" onclick="document.getElementById('img1').click()">
          <span id="label1">Chọn hoặc kéo thả ảnh 1</span>
          <input type="file" id="img1" name="image1" accept="image/*" required>
          <img id="prev1" class="preview" alt="Preview 1">
        </div>
      </div>
      <div class="card">
        <h3>Ảnh 2 (Candidate)</h3>
        <div class="dropzone" onclick="document.getElementById('img2').click()">
          <span id="label2">Chọn hoặc kéo thả ảnh 2</span>
          <input type="file" id="img2" name="image2" accept="image/*" required>
          <img id="prev2" class="preview" alt="Preview 2">
        </div>
      </div>
    </div>

    <div class="controls">
      <label>Ngưỡng Cosine (Threshold):</label>
      <input type="number" id="threshold" name="threshold" value="0.45" step="0.05" min="0" max="1">
      <button type="button" class="preset-btn" onclick="setThresh(0.40)">0.40 (Nới lỏng - Ảnh đời thường)</button>
      <button type="button" class="preset-btn" onclick="setThresh(0.45)">0.45 (Chuẩn ArcFace FAR 10⁻⁴)</button>
      <button type="button" class="preset-btn" onclick="setThresh(0.55)">0.55 (Bảo mật cao - Ảnh thẻ)</button>
      <button type="button" class="preset-btn" onclick="setThresh(0.68)">0.68 (Mặc định)</button>
      <button type="submit" id="btnSubmit" class="submit-btn">So sánh 2 ảnh (qua BE)</button>
    </div>
  </form>

  <div id="resultBox" class="result">
    <div id="resultStatus" class="score"></div>
    <div id="resultDesc"></div>

    <div class="liveness-box" id="livenessBox" style="display:none;">
      <div class="liveness-item" id="liveItem1"></div>
      <div class="liveness-item" id="liveItem2"></div>
    </div>

    <div class="expl-box">
      <strong>Đường truyền kiểm tra:</strong> Trình duyệt &rarr; NestJS Controller (/face-test/compare) &rarr; FaceGrpcAdapter &rarr; Python gRPC Server (localhost:50051) &rarr; Trả kết quả JSON.
    </div>

    <pre id="resultJson"></pre>
  </div>

  <script>
    function setThresh(v) {
      document.getElementById('threshold').value = v.toFixed(2);
    }

    function bindPreview(inputId, prevId, labelId) {
      document.getElementById(inputId).addEventListener('change', e => {
        const file = e.target.files[0];
        if (file) {
          const reader = new FileReader();
          reader.onload = ev => {
            const p = document.getElementById(prevId);
            p.src = ev.target.result;
            p.style.display = 'block';
            document.getElementById(labelId).innerText = file.name;
          };
          reader.readAsDataURL(file);
        }
      });
    }
    bindPreview('img1', 'prev1', 'label1');
    bindPreview('img2', 'prev2', 'label2');

    document.getElementById('compareForm').addEventListener('submit', async e => {
      e.preventDefault();
      const btn = document.getElementById('btnSubmit');
      const box = document.getElementById('resultBox');
      const statusEl = document.getElementById('resultStatus');
      const descEl = document.getElementById('resultDesc');
      const jsonEl = document.getElementById('resultJson');
      const livenessBox = document.getElementById('livenessBox');
      const liveItem1 = document.getElementById('liveItem1');
      const liveItem2 = document.getElementById('liveItem2');

      btn.disabled = true;
      btn.innerText = 'Đang nhận diện qua BE...';
      box.style.display = 'none';
      livenessBox.style.display = 'none';

      const formData = new FormData();
      formData.append('image1', document.getElementById('img1').files[0]);
      formData.append('image2', document.getElementById('img2').files[0]);
      formData.append('threshold', document.getElementById('threshold').value);

      try {
        const res = await fetch('/face-test/compare', { method: 'POST', body: formData });
        const data = await res.json();
        box.style.display = 'block';
        jsonEl.innerText = JSON.stringify(data, null, 2);

        if (data.liveness && data.liveness.image1 && data.liveness.image2) {
          liveItem1.innerHTML = '<strong>Ảnh 1 Liveness:</strong> ' + data.liveness.image1.status + ' (' + (data.liveness.image1.confidence * 100).toFixed(1) + '%)' + (data.liveness.image1.is_live ? ' &#9989;' : ' &#10060;');
          liveItem2.innerHTML = '<strong>Ảnh 2 Liveness:</strong> ' + data.liveness.image2.status + ' (' + (data.liveness.image2.confidence * 100).toFixed(1) + '%)' + (data.liveness.image2.is_live ? ' &#9989;' : ' &#10060;');
          livenessBox.style.display = 'flex';
        }

        if (data.error) {
          box.className = 'result error';
          statusEl.innerText = 'LỖI: ' + data.error;
          descEl.innerText = data.grpc_compat_status ? 'Trạng thái gRPC: ' + data.grpc_compat_status : '';
        } else if (data.matched) {
          box.className = 'result matched';
          statusEl.innerText = 'CÙNG MỘT NGƯỜI (Độ tin cậy: ' + data.match_confidence + '%)';
          descEl.innerText = 'Cosine Similarity: ' + data.similarity + ' | Khoảng cách Euclidean: ' + data.euclidean_distance + ' (Ngưỡng: ' + data.threshold + ') | ' + data.security_level;
        } else {
          box.className = 'result unmatched';
          statusEl.innerText = 'KHÁC NGƯỜI (Độ tin cậy: ' + data.match_confidence + '%)';
          descEl.innerText = 'Cosine Similarity: ' + data.similarity + ' | Khoảng cách Euclidean: ' + data.euclidean_distance + ' (Ngưỡng: ' + data.threshold + ') | ' + data.security_level;
        }
      } catch (err) {
        box.style.display = 'block';
        box.className = 'result error';
        statusEl.innerText = 'Lỗi kết nối Backend';
        descEl.innerText = err.message;
      } finally {
        btn.disabled = false;
        btn.innerText = 'So sánh 2 ảnh (qua BE)';
      }
    });
  </script>
</body>
</html>
`;

@Controller('face-test')
export class FaceTestController {
  constructor(private readonly faceGrpcAdapter: FaceGrpcAdapter) {}

  @Get()
  @Header('Content-Type', 'text/html; charset=utf-8')
  getIndex(): string {
    return HTML_PAGE;
  }

  @Post('compare')
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'image1', maxCount: 1 },
      { name: 'image2', maxCount: 1 },
    ]),
  )
  async compare(
    @UploadedFiles()
    files: {
      image1?: UploadedFile[];
      image2?: UploadedFile[];
    },
    @Body('threshold') thresholdStr?: string,
  ) {
    const start = performance.now();
    const threshold = thresholdStr ? parseFloat(thresholdStr) : 0.45;

    const img1 = files?.image1?.[0];
    const img2 = files?.image2?.[0];

    if (!img1?.buffer || !img2?.buffer) {
      return {
        error: 'Vui lòng tải lên cả Ảnh 1 và Ảnh 2.',
        matched: false,
      };
    }

    try {
      // 1. Kiểm tra DetectFaces qua gRPC
      const [faces1, faces2] = await Promise.all([
        this.faceGrpcAdapter.detect(img1.buffer),
        this.faceGrpcAdapter.detect(img2.buffer),
      ]);

      if (!faces1.length) {
        return {
          error: 'Không tìm thấy khuôn mặt trong Ảnh 1 (Reference)',
          matched: false,
          faces_found: { image1: 0, image2: faces2.length },
        };
      }
      if (!faces2.length) {
        return {
          error: 'Không tìm thấy khuôn mặt trong Ảnh 2 (Candidate)',
          matched: false,
          faces_found: { image1: faces1.length, image2: 0 },
        };
      }

      // 2. Kiểm tra ExtractEmbedding qua gRPC
      const [emb1, emb2] = await Promise.all([
        this.faceGrpcAdapter.extractEmbedding(img1.buffer, faces1[0].bbox),
        this.faceGrpcAdapter.extractEmbedding(img2.buffer, faces2[0].bbox),
      ]);

      // 3. Kiểm tra VerifyFace qua gRPC
      const verifyRes = await this.faceGrpcAdapter.verify(
        img2.buffer,
        emb1,
        threshold,
      );

      // 4. Kiểm tra CheckLiveness qua gRPC
      const [liveness1, liveness2] = await Promise.all([
        this.faceGrpcAdapter.checkLiveness(img1.buffer),
        this.faceGrpcAdapter.checkLiveness(img2.buffer),
      ]);

      const similarity = verifyRes.similarity;
      const matched = verifyRes.matched;
      const euclideanDist = Math.sqrt(Math.max(0, 2 * (1 - similarity)));
      const matchConfidence = computeMatchConfidence(similarity);

      let securityLevel = 'Không trùng khớp (Negative)';
      if (similarity >= 0.55) {
        securityLevel = 'Trùng khớp cực cao (FAR < 0.001%)';
      } else if (similarity >= 0.45) {
        securityLevel = 'Trùng khớp độ tin cậy cao (FAR < 0.01%)';
      } else if (similarity >= 0.38) {
        securityLevel = 'Trùng khớp mức chấp nhận được (FAR ~ 0.1%)';
      }

      const elapsedMs = Math.round(performance.now() - start);

      return {
        matched,
        similarity: Number(similarity.toFixed(4)),
        match_confidence: matchConfidence,
        security_level: securityLevel,
        euclidean_distance: Number(euclideanDist.toFixed(4)),
        threshold,
        faces_found: {
          image1: faces1.length,
          image2: faces2.length,
        },
        detections: {
          image1: {
            bbox: faces1[0].bbox,
            confidence: faces1[0].confidence,
            landmarks_count: faces1[0].landmarks?.points?.length ?? 0,
          },
          image2: {
            bbox: faces2[0].bbox,
            confidence: faces2[0].confidence,
            landmarks_count: faces2[0].landmarks?.points?.length ?? 0,
          },
        },
        embedding: {
          dimension_1: emb1.dimension,
          dimension_2: emb2.dimension,
        },
        liveness: {
          image1: {
            status: liveness1.status,
            is_live: liveness1.isLive(),
            confidence: Number(liveness1.confidence.toFixed(4)),
          },
          image2: {
            status: liveness2.status,
            is_live: liveness2.isLive(),
            confidence: Number(liveness2.confidence.toFixed(4)),
          },
        },
        grpc_compat_status: 'ALL_PASS',
        elapsed_ms: elapsedMs,
      };
    } catch (err: any) {
      return {
        error: `Lỗi kết nối hoặc xử lý gRPC: ${err.message || String(err)}`,
        matched: false,
        grpc_compat_status: 'FAILED',
        elapsed_ms: Math.round(performance.now() - start),
      };
    }
  }
}
