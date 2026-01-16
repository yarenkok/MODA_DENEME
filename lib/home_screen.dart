import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moda_asistani/analiz_screen.dart';
import 'package:moda_asistani/weather_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:moda_asistani/login_screen.dart'; // For API Key

class TarzSecimScreen extends StatefulWidget {
  final String gender;
  const TarzSecimScreen({super.key, required this.gender});

  @override
  State<TarzSecimScreen> createState() => _TarzSecimScreenState();
}

class _TarzSecimScreenState extends State<TarzSecimScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  final Map<String, String> _savedMoodboardIds = {}; // title -> docId
  List<Map<String, String>> _moodboardItems = [];
  bool _moodboardLoading = false;
  int? _moodboardRefreshingIndex;

  Future<void> _pickStudioImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source, maxWidth: 1000);
    if (picked != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalizScreen(
            gender: widget.gender,
            initialImage: File(picked.path),
            weatherInfo: _weatherData != null
                ? "${_weatherData!['name']}, ${_weatherData!['main']['temp'].round()}°C"
                : "Bilinmiyor",
          ),
        ),
      );
    }
  }

  List<Map<String, String>> get stiller {
    final bool isUserFemale = widget.gender == 'Kadın';
    
    return [
      {
        'ad': 'Klasik',
        'img': isUserFemale 
            ? 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop'
            : 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?q=80&w=800&auto=format&fit=crop'
      },
      {
        'ad': 'Spor',
        'img': isUserFemale
            ? 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop'
            : 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=800&auto=format&fit=crop'
      },
      {
        'ad': 'Günlük',
        'img': isUserFemale
            ? 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop'
            : 'https://images.unsplash.com/photo-1488161628813-f446ce1ba468?q=80&w=800&auto=format&fit=crop'
      },
      {
        'ad': 'Şık',
        'img': isUserFemale
            ? 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop'
            : 'https://images.unsplash.com/photo-1505022610485-0249ba5b3675?q=80&w=800&auto=format&fit=crop'
      },
      {
        'ad': 'Vintage',
        'img': isUserFemale
            ? 'https://images.unsplash.com/photo-1502716119720-b23a93e5fe1b?q=80&w=800&auto=format&fit=crop'
            : 'https://images.unsplash.com/photo-1550246140-5119ae4790b8?q=80&w=800&auto=format&fit=crop'
      },
      {
        'ad': 'Sokak Modası',
        'img': isUserFemale
            ? 'https://images.unsplash.com/photo-1529139572765-39d487efdf10?q=80&w=800&auto=format&fit=crop'
            : 'https://images.unsplash.com/photo-1523398002811-999ca8dec234?q=80&w=800&auto=format&fit=crop'
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _fetchFavorites();
    _initMoodboard();
  }

  void _initMoodboard() {
    final bool isUserFemale = widget.gender == 'Kadın';
    setState(() {
      _moodboardItems = isUserFemale ? [
        {'title': 'Night Out Capsule', 'arama_terimi': 'aesthetic minimalist editorial black woman outfit flatlay luxury clothing'},
        {'title': 'Siyah İhtişamı', 'arama_terimi': 'vogue style minimalist black outfit flatlay luxury apparel'},
        {'title': 'İnci Minimalizmi', 'arama_terimi': 'high-end editorial pearl outfit flatlay minimalist clothing'},
      ] : [
        {'title': 'Urban Layering', 'arama_terimi': 'vogue style men outfit minimalist apparel flatlay high-end'},
        {'title': 'Modern Noir', 'arama_terimi': 'minimalist black men outfit flatlay editorial clothing luxury'},
        {'title': 'Grey Capsule', 'arama_terimi': 'luxury suit grey flatlay editorial apparel minimalist fashion'},
      ];
    });
  }

  Future<void> _regenerateMoodboardItem(int index) async {
    if (_moodboardLoading) return;

    setState(() {
      _moodboardRefreshingIndex = index;
    });

    try {
      final model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
      final String currentItem = _moodboardItems[index]['title'] ?? '';
      final String genderPrompt = widget.gender == 'Kadın' ? 'kadın' : 'erkek';
      
      final prompt = """
      Sen dünyanın en iyi lüks moda editörüsün. Kullanıcı şu moda kapsülünü (hap kombin) beğenmedi: "$currentItem".
      Lütfen bu kapsülün yerine geçecek, yine $genderPrompt modasına uygun, VESTIS ONE minimalist estetiğinde (Siyah, Beyaz, Gri paleti) YENİ bir "Hap Kombin" öner.
      
      Yanıtını SADECE şu JSON formatında ver:
      {
        "title": "yeni kapsül adı (kısa, vurucu)",
        "arama_terimi": "aesthetic Pinterest style flatlay [piece_name] minimalist vogue editorial high-end clothing"
      }
      
      Önemli: 'arama_terimi' mutlaka İngilizce olmalı ve bir Pinterest flatlay çekimini yansıtacak detaylandırılmalıdır. "fashion" kelimesini kullanmaktan kaçın, bunun yerine editoryal moda terimlerini kullan.
      """;

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        debugPrint("Gemini Moodboard Refresh Response: ${response.text}");
        String cleanedJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> decoded = jsonDecode(cleanedJson);
        
        setState(() {
          _moodboardItems[index] = {
            'title': decoded['title'] ?? 'Yeni Stil',
            'arama_terimi': decoded['arama_terimi'] ?? 'fashion flatlay minimalist',
          };
        });
      }
    } catch (e) {
      debugPrint("Kombin yenileme hatası: $e");
    } finally {
      if (mounted) setState(() => _moodboardRefreshingIndex = null);
    }
  }

  Future<void> _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();
      
      if (mounted) {
        setState(() {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['is_moodboard'] == true && data['parca_adi'] != null) {
              _savedMoodboardIds[data['parca_adi']] = doc.id;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Favoriler çekme hatası: $e");
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final data = await _weatherService.getWeather();
      if (mounted) setState(() => _weatherData = data);
    } catch (e) {
      debugPrint("Hava durumu hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI HAP KOMBİNLER",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bu Haftanın Favorileri",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSezonMoodboard(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CURATED COLLECTIONS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tarzınıza Göre Keşfedin",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  return _buildMagazineCard(context, i);
                },
                childCount: stiller.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(User? user) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.asset(
              "assets/images/logo.png",
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (ctx, _, __) => const Text(
                "VESTIS ONE",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2),
              ),
            ),
          ),
          if (_weatherData != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 10, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  "${(_weatherData!['name'] ?? 'KONUM ALINDI').toUpperCase()} • ${_weatherData!['main']['temp'].round()}°C",
                  style: const TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: Colors.black54, 
                    letterSpacing: 0.5
                  ),
                ),
              ],
            )
          else 
            GestureDetector(
              onTap: _fetchWeather,
              child: Row(
                children: [
                  const Icon(Icons.location_off_outlined, size: 10, color: Colors.black45),
                  const SizedBox(width: 4),
                  const Text(
                    "LÜTFEN KONUMU AÇIN",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black, size: 22),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFF2F2F7),
            backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                ? (user!.photoURL!.startsWith('http') 
                    ? NetworkImage(user!.photoURL!) as ImageProvider
                    : FileImage(File(user!.photoURL!.startsWith('file') 
                        ? Uri.parse(user!.photoURL!).toFilePath() 
                        : user!.photoURL!)))
                : null,
            child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                ? const Icon(Icons.person_outline, size: 18, color: Colors.black45) 
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSezonMoodboard(BuildContext context) {
    // AI-Generated 'Hap Kombinler' (Pinterest-style Flat Lay Capsules)
    // Now using _moodboardItems from state

    return Container(
      height: 280,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _moodboardItems.length,
        itemBuilder: (context, i) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_moodboardItems[i]['arama_terimi'] != null || _moodboardItems[i]['title'] != null)
                          Image.network(
                            'https://loremflickr.com/600/800/fashion,outfit,${Uri.encodeComponent((_moodboardItems[i]['arama_terimi'] ?? 'outfit,flatlay,clothing').replaceAll(' ', ','))}/all?lock=${(_moodboardItems[i]['title'] ?? 'style').hashCode}',
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFFF2F2F7),
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black12)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF2F2F7),
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined, color: Colors.black12, size: 30),
                              ),
                            ),
                          ),
                        // Overlay and Shadow for text readability (optional, but keep it clean)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
                              ),
                            ),
                          ),
                        ),
                        if (_moodboardRefreshingIndex == i)
                          const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: GestureDetector(
                            onTap: () {
                            if (_moodboardRefreshingIndex == null) _regenerateMoodboardItem(i);
                          },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.refresh, size: 16, color: Colors.black),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _toggleMoodboardFavorite(_moodboardItems[i]),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _savedMoodboardIds.containsKey(_moodboardItems[i]['title']) 
                                    ? const Color(0xFF121212) 
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  if (!_savedMoodboardIds.containsKey(_moodboardItems[i]['title']!))
                                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                ],
                              ),
                              child: Icon(
                                _savedMoodboardIds.containsKey(_moodboardItems[i]['title']) 
                                    ? Icons.favorite 
                                    : Icons.favorite_outline,
                                size: 16,
                                color: _savedMoodboardIds.containsKey(_moodboardItems[i]['title']) 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.auto_awesome_outlined, size: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _moodboardItems[i]['title']!.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleMoodboardFavorite(Map<String, String> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String title = item['title'] ?? '';
    final bool isAlreadySaved = _savedMoodboardIds.containsKey(title);

    try {
      if (isAlreadySaved) {
        final docId = _savedMoodboardIds[title];
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(docId)
            .delete();
        
        setState(() {
          _savedMoodboardIds.remove(title);
        });
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .add({
          'parca_adi': title,
          'aciklama': "Sezon Trendi: $title",
          'arama_terimi': title,
          'img_url': item['img'],
          'is_moodboard': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _savedMoodboardIds[title] = docRef.id;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title gardırobuna eklendi! ✨"),
              backgroundColor: Colors.black,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Moodboard favori hatası: $e");
      if (e.toString().contains('permission-denied')) {
        _showPermissionError();
      }
    }
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Hata: Firebase Firestore izinleri kapalı. Lütfen Firestore kurallarını kontrol edin."),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMagazineCard(BuildContext context, int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (i * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnalizScreen(
                tarz: stiller[i]['ad']!,
                gender: widget.gender,
                weatherInfo: _weatherData != null
                    ? "${_weatherData!['name']}, ${_weatherData!['main']['temp'].round()}°C"
                    : "Bilinmiyor",
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  image: DecorationImage(
                    image: NetworkImage(stiller[i]['img']!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              stiller[i]['ad']!.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "STYLE GUIDE",
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Colors.black.withOpacity(0.3),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
