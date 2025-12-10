# Hastane ER Frontend (Vite + React)

## Çalıştırma

```bash
cd frontend
npm install
npm run dev
```

## API Adresi

- Varsayılan: `http://localhost:8080/api`
- Özelleştirme: `env.example` dosyasını kopyalayıp `VITE_API_BASE` değeriyle `.env` oluşturun.

## Notlar

- Kimlik doğrulama Basic Auth ile yapılır; token `localStorage`'da `auth` anahtarıyla saklanır.
- Vite dev sunucusu `5173` portundan çalışacak şekilde ayarlıdır.
