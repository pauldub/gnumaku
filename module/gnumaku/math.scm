(define-module (gnumaku math))
(export pi deg2rad cos-deg sin-deg)

(define pi 3.141592654)

(define (deg2rad angle)
  (* angle (/ pi 180)))

(define (cos-deg angle)
  (cos (deg2rad angle)))

(define (sin-deg angle)
  (sin (deg2rad angle)))
