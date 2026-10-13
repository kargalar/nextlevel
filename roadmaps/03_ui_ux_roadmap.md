# UI & UX İyileştirmeleri Yol Haritası

Bu dosya, 🎨 **UI & UX İyileştirmeleri** kategorisindeki arayüz ve kullanıcı deneyimi görevlerinin detaylı teknik adımlarını içerir.

## 1. Kilit Ekranı Timer Bildirimi (Task Adı Gösterimi)
- **Sorun:** Bildirimde genel geçer "NextLevel" yazması yerine dinamik olarak çalışılan taskın adının yazması isteniyor.
- **Çözüm Adımları:**
  1. `flutter_local_notifications` veya arkaplan timer servisini başlattığınız koda gidin.
  2. Servisi başlatırken gönderilen (payload / title) parametrelerini bulun.
  3. Hardcoded olarak yazılan `"NextLevel"` stringini, o an aktif olan görevden çekilecek olan `task.name` değişkeni ile değiştirin. (Örnek: `title: "${task.name} . $remainingTime"`).
  4. Arkaplan servisi her güncellendiğinde bu verinin doğru yansıdığından emin olun.

## 2. İlerleme Grafiği (Günlük, Haftalık, Aylık)
- **Kapsam:** Skill detay sayfasındaki gelişimi gösteren bir grafik oluşturmak.
- **Çözüm Adımları:**
  1. Projeye `fl_chart` paketini ekleyin (modern ve performanslı grafikler için en uygunudur).
  2. UI üzerine "Günlük", "Haftalık" ve "Aylık" seçeneklerini içeren bir `ToggleButtons` veya `SegmentedControl` ekleyin.
  3. Seçilen zaman aralığına göre veritabanından ilgili yetenek (skill) için logları filtreleyen bir fonksiyon yazın.
  4. Verileri `LineChart` veya `BarChart` widget'ına bağlayın (X ekseni: zaman, Y ekseni: kazanılan XP veya tamamlanan task sayısı).

## 3. Kazanılan Kredi Bildirimi
- **Kapsam:** Bir task tamamlandığında kullanıcıya gösterilen mesajda sadece "Tebrikler" değil, "Şu kadar kredi kazandınız" bilgisinin de verilmesi.
- **Çözüm Adımları:**
  1. Görev `isDone = true` yapıldığında çalışan UI tetikleyicisini bulun.
  2. O görev için tanımlanmış ödül miktarını (kredi) tespit edin.
  3. UI tarafında gösterilen `SnackBar`, `Toast` veya `Dialog` mesajını güncelleyin.
  4. Eski: `"Görev tamamlandı!"` -> Yeni: `"Görev tamamlandı! 🎉 +$gainedCredit Kredi kazandınız."`
  5. UI zenginliğini artırmak için yazının yanına küçük bir jeton (coin) ikonu ekleyebilirsiniz.
