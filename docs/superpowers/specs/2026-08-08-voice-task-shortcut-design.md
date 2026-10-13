# Sesli Görev Kısayolu Tasarımı

**Tarih:** 2026-08-08  
**Durum:** Kullanıcı tarafından onaylandı; uygulama planına geçmeden önce inceleme bekliyor

## Amaç

Next Level kullanıcılarının Android ana ekranındaki “Sesli görev ekle” kısayolundan hızlıca görev oluşturabilmesi.

Kısayol, uygulamayı tam ekran açılmış gibi göstermeden ana ekranın üzerinde alttan açılan bir sesli görev paneli sunar. Kullanıcı konuşur, tanınan metni görür/düzenler ve görev yalnızca “Ekle” butonuna bastığında kaydedilir.

## Kapsam

- Android ana ekranı için bir uygulama kısayolu.
- Kısayol açıldığında Android ana ekranı arkada görünürken şeffaf/yarı saydam bir uygulama penceresinde Flutter paneli.
- Telefonun konuşma tanıma motoru üzerinden ses-metin dönüşümü.
- Varsayılan konuşma dili olarak telefon dili.
- Ayarlardan desteklenen konuşma dillerinden birini seçebilme ve seçimi kalıcı saklama.
- Tanınan metni düzenleme ve “Ekle” ile checkbox görev oluşturma.
- Mevcut `TaskProvider.addTask` akışının, ev widget güncellemesinin ve yerel/senkronizasyon davranışının yeniden kullanılması.

İlk sürümde arka planda sürekli dinleme, özel uyandırma kelimesi, bulut tabanlı ses servisi ve ses kaydı saklama yoktur. iOS için tam ekran Quick Action davranışı ayrı bir platform çalışması olarak kapsam dışındadır; bu tasarım Android ana ekranı deneyimine odaklanır.

## Kullanıcı akışı

1. Kullanıcı Android ana ekranındaki “Sesli görev ekle” kısayoluna dokunur.
2. Next Level, kısayol intent’ini alır ve sesli görev panelini açar.
3. Pencere saydam/yarı saydamdır; launcher ana ekranı panelin arkasında görünür.
4. Mikrofon izni yoksa izin istenir. İzin verildikten sonra dinleme başlatılır.
5. Kullanıcı konuşurken tanınan metin panelde gösterilir.
6. Dinleme durduğunda metin düzenlenebilir alanda kalır.
7. Metin boş değilse “Ekle” etkinleşir. Kullanıcı “Ekle”ye basınca checkbox görev oluşturulur.
8. Görev kaydı tamamlanınca panel kapanır ve Android ana ekranına dönülür.
9. Kullanıcı iptal ederse veya kayıt başarısız olursa mevcut metin korunarak tekrar deneme olanağı sunulur.

## Varsayılan görev değerleri

Sesli görevler mevcut hızlı görev akışıyla aynı temel modeli kullanır:

- Tür: `TaskTypeEnum.CHECKBOX`
- Başlık: tanınan ve kullanıcının onayladığı metin
- Tarih: bugün
- Saat: yok
- Bildirim/alarm: kapalı
- Öncelik: düşük (`3`)
- Açıklama: yok
- Tekrar, kategori, rutin ve alt görev: yok

## Mimari

### Flutter katmanı

`VoiceTaskPage` sesli görev panelinin görsel durumlarını ve kullanıcı etkileşimlerini yönetir. Panel tam bir sayfa yerine alttan açılan `BottomSheet` benzeri bir yüzey olarak çizilir.

`VoiceTaskProvider` şu durumları yönetir:

- Başlangıç/izin kontrolü
- Dinleme başladı, dinliyor, durdu ve sonuç hazır durumları
- Tanınan metin
- Kayıt işlemi ve hata durumu
- Tekrar deneme ve iptal

`SpeechRecognitionService`, seçili dil ve mikrofon/konuşma tanıma motoruyla ilgili platform ayrıntılarını kapsüller. Üst katman bu servisin paket/API ayrıntılarına bağımlı olmaz.

`VoiceTaskProvider`, onaydan sonra `TaskModel` oluşturur ve `TaskProvider().addTask(...)` çağrısını kullanır. Böylece ID üretimi, Hive kaydı, görev listesi, widget yenileme ve mevcut görev davranışları tek noktada kalır.

### Android katmanı

Mevcut `MainActivity` kısayol intent’ini hem soğuk başlangıçta hem de uygulama zaten açıkken alır. `voice_task_shortcut` işareti Flutter tarafına aktarılır.

Kısayol yolu için activity penceresi saydam/yarı saydam bir tema ile başlatılır; normal uygulama açılışında mevcut opak tema korunur. Kısayol akışı tamamlandığında activity sonlandırılarak launcher’a dönülür.

Android App Shortcut, ana launcher activity’sine sesli görev hedefiyle bağlanır. Kullanıcının kısayolu ana ekrana sabitleyebilmesi için statik/dinamik shortcut tanımı ve platformun desteklediği sabitleme akışı kullanılacaktır. İlk sürümde ayrı bir widget ile ses tanıma yapılmayacaktır; widget yalnızca paneli açan bir buton olabilecek ve canlı Flutter ses akışını barındırmayacaktır.

### Ayarlar

Settings sayfasına “Sesli görev dili” seçeneği eklenir:

- “Telefon dili” varsayılan seçenektir.
- Kullanıcı, konuşma motorunun sunduğu diller arasından seçim yapar.
- Seçim `SharedPreferences` içinde saklanır.
- Kullanıcı “Telefon dili”ni seçerse kayıtlı özel seçim temizlenir.
- Desteklenmeyen veya bulunamayan dil için anlaşılır hata ve telefon diliyle tekrar deneme gösterilir.

## Durum ve hata davranışları

- Mikrofon izni reddedilirse panel açıklama, “Ayarları aç” ve iptal seçeneklerini gösterir.
- Konuşma tanıma cihazda kullanılamıyorsa manuel başlık girişi açık kalır.
- Hiçbir konuşma algılanmazsa metin boş kalır ve “Tekrar dene” gösterilir.
- Tanıma zaman aşımına uğrarsa mevcut kısmi metin kaybolmaz.
- “Ekle”, yalnızca `trim()` sonrası metin boş değilse etkin olur.
- Görev kaydı hata verirse metin korunur; kullanıcı tekrar deneyebilir veya paneli kapatabilir.
- Uygulama arka planda sürekli mikrofon dinlemez ve tanınan ses verisini saklamaz.

## Test stratejisi

### Birim testleri

- Varsayılan/özel dil tercihini yükleme ve kaydetme.
- Boş metinde “Ekle” işleminin reddedilmesi.
- Metnin `TaskModel` içine checkbox, bugün, düşük öncelik ve bildirimsiz değerlerle aktarılması.
- Onay sonrası `TaskProvider.addTask` akışının kullanılması.
- Dinleme, sonuç, hata ve tekrar deneme durum geçişleri.

### Widget testleri

- Tanıma metninin düzenlenebilir alanda görünmesi.
- Boş metinde “Ekle” butonunun pasif olması.
- Dolu metinde “Ekle” butonunun etkin olması.
- Ekle’ye basınca yükleniyor durumu ve başarı sonrası kapanma.
- İzin reddi, tanıma hatası ve tekrar deneme mesajları.

### Android doğrulaması

- Kısayolun launcher’da görünmesi ve ana ekrana sabitlenebilmesi.
- Uygulama kapalıyken kısayolun paneli açması.
- Uygulama açıkken kısayolun ikinci bir pencere/route karmaşası oluşturmaması.
- Panel arkasında ana ekranın görünmesi ve iptal/ekle sonrası launcher’a dönülmesi.
- Mikrofon izni akışı ve ayarlar ekranına yönlendirme.

## Başarı ölçütleri

- Kullanıcı kısayola dokunduktan sonra tam görev listesini görmek zorunda kalmadan sesli görev paneline ulaşır.
- Tanınan metin kullanıcı tarafından görülmeden ve “Ekle” onayı alınmadan kaydedilmez.
- Onaylanan metin mevcut görev listesinde normal checkbox görev olarak görünür.
- Dil seçimi uygulama yeniden başlatıldıktan sonra korunur.
- İzin, tanıma ve kayıt hatalarında kullanıcı metni kaybetmez.
- Android ana ekranına dönüş akışı cihaz yeniden başlatıldığında veya uygulama soğuk açıldığında çalışır.
