#VESTIS ONE

Yapay Zeka Destekli Moda Asistanı VestisOne, kullanıcıların organlarındaki donanımlarını optimize etmelerine olanak sağlayan, Flutter mimarisiyle geliştirilmiş bir yapay zeka uygulamasıdır.

Proje Vizyonu Kullanıcılara kişiselleştirilmiş stil yatırım sunarak seçim sürecini dijitalleştirmek ve moda tercihlerindeki karar verme süreçlerini yapay zeka desteğiyle optimize etmektir.

Temel Sorular ve Yanıtlar Kullanıcı Kitlesi Moda Takipçileri: Güncel trendlere uygun stil önerilerine uygun bireyler.

Profesyoneller: Günlük hazırlık süreci zaman harcayan kullanıcıların tasarruf etmesini sağlar.

Sürdürülebilir Moda Destekçileri: Dileyenler mevcut kayıtlarını verimli kullanarak tüketim miktarlarını organize edebilirler.

Çözüm Sunulan Sorunlar Karar Verme Süreçleri: Günlük kombi hazırlama aşamasındaki kararsızlık ve en az indirir.

Stil Tutarlılığı: Belirlenen moda akımlarına (Streetwear, Klasik vb.) göre parça analiziyle üretilen stil hatalarının önüne geçilir.

Uygulama Alanı ve Metodoloji Kullanım Alanı: Mobil platformlar üzerinden ev ortamında veya alışveriş sırasında gerçek zamanlı kullanım.

İşleyiş: Kullanıcı ile ilgili stil modu seçilir ve görsel olarak sistem yüklenir. Google Gemini AI ile görsel veriler saniyeler içinde analiz edilerek sunulur.

Teknik Altyapı ve Kurulum Temel Bağımlılar (pubspec.yaml) Projenin çözmek için aşağıdaki kurulumler kullanılır:

google_generative_ai: ^0.4.7 - Yapay Wi-Fi modelinin etkileşimi.

image_picker: ^1.1.2 - Medya erişimi ve görsel işleme.

Teknik Zorluklar ve Çözüm Yaklaşımları Geliştirme olarak kontrol ve model uyumluluğu sorunları şu şekilde çözülmüştür:

Hata Yönetimi: Model erişim hataları (gemini-3-uzunlukları) uygun API değişimi ile giderilmiştir.

Ağ Protokolleri: Emülatör ortamında gerçekleşen SocketException (Ana Bilgisayar adı arama) sorunları, ağ izinleri ve DNS düzenlemeleriyle optimize edilmiştir.

Geliştirme Takvimi (Yol Haritası) [x] Temel Arayüz Tasarımı (Stil Seçimi ve Öneri Ekranları) [x] Gemini AI Entegrasyonu [x] Hava Durumu Servis Entegrasyonu

Bu çalışma bir eğitim ve geliştirme projesi kapsamında hazırlanmıştır. Uygulamamın youtube video linki : https://youtu.be/SnTyIzgQzO4
