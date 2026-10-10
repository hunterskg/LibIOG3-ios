import { Observable } from 'rxjs';

export interface GrpcBoundingBox {
  x: number;
  y: number;
  width: number;
  height: number;
  confidence: number;
}

export interface GrpcLandmark {
  x: number;
  y: number;
  index: number;
}

export interface GrpcFaceDetection {
  box: GrpcBoundingBox;
  landmarks: GrpcLandmark[];
  confidence: number;
}

export interface GrpcFaceEmbedding {
  values: readonly number[];
  dimension: number;
}

// Khai báo 4 RPC method tương ứng trong file face.proto
export interface GrpcFaceService {
  detectFaces(data: {
    image_bytes: Buffer;
    image_format?: number;
    max_faces?: number;
  }): Observable<{
    detections: GrpcFaceDetection[];
    success: boolean;
    error: string;
  }>;

  extractEmbedding(data: {
    image_bytes: Buffer;
    image_format?: number;
    bbox?: GrpcBoundingBox;
  }): Observable<{
    embedding: GrpcFaceEmbedding;
    success: boolean;
    error: string;
  }>;

  verifyFace(data: {
    image_bytes: Buffer;
    image_format?: number;
    reference_embedding: GrpcFaceEmbedding;
    bbox?: GrpcBoundingBox;
    threshold?: number;
  }): Observable<{
    matched: boolean;
    similarity: number;
    success: boolean;
    error: string;
  }>;

  checkLiveness(data: {
    image_bytes: Buffer;
    image_format?: number;
  }): Observable<{
    status: number;
    confidence: number;
    success: boolean;
    error: string;
  }>;
}
