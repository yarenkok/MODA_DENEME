import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moda_asistani/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  int _savedCount = 0;
  int _analysisCount = 0;
  int _avgScore = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (user == null) return;
    try {
      // 1. Favori Sayısı
      final favSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .get();
      
      // 2. Analiz Sayısı ve Stil Uyumu
      final analysisSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('analyses')
          .get();

      if (mounted) {
        setState(() {
          _savedCount = favSnapshot.docs.length;
          _analysisCount = analysisSnapshot.docs.length;
          
          if (_analysisCount > 0) {
            double totalScore = 0;
            for (var doc in analysisSnapshot.docs) {
              totalScore += (doc.data()['style_score'] ?? 0);
            }
            _avgScore = (totalScore / _analysisCount).round();
          } else {
            _avgScore = 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Stat hatası: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? picked = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Profil Fotoğrafı Seç", style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Kamera"),
              onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.camera)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galeri"),
              onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.gallery)),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      final File file = File(picked.path);
      setState(() {
        _profileImage = file;
      });
      
      try {
        if (user != null) {
          // 1. Firebase Storage'a Yükle
          final ref = FirebaseStorage.instance.ref().child('users/${user!.uid}/profile_pics/avatar.jpg');
          await ref.putFile(file);
          final String downloadUrl = await ref.getDownloadURL();
          
          // 2. Kullanıcı Profilini Güncelle
          await user!.updatePhotoURL(downloadUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profil fotoğrafı güncellendi! ✨")),
            );
          }
        }
      } catch (e) {
        debugPrint("Photo upload error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Yükleme hatası: $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const SizedBox(height: 30),
                  _buildStatsSection(context),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, "ÜYELİK & AVANTAJLAR"),
                  const SizedBox(height: 15),
                  _buildMembershipSection(),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, "PROFİL AYARLARI"),
                  const SizedBox(height: 15),
                  _buildMenuCard([
                    _buildMenuItem(context, Icons.person_outline, "Hesap Bilgileri", user?.email ?? "E-posta bulunamadı"),
                    _buildMenuItem(context, Icons.notifications_none, "Bildirimler", "Tüm bildirimler açık"),
                    _buildMenuItem(context, Icons.security_outlined, "Güvenlik", "Şifre ve Güvenlik"),
                  ]),
                  const SizedBox(height: 30),
                  _buildSectionTitle(context, "MODA DÜNYASI"),
                  const SizedBox(height: 15),
                  _buildMenuCard([
                    _buildMenuItem(context, Icons.auto_awesome_outlined, "Stil Analitiği", "Haftalık tarz özeti"),
                    _buildMenuItem(context, Icons.card_membership_outlined, "Moda Kulübü", "Silver Member Avantajları"),
                    _buildMenuItem(context, Icons.share_outlined, "Arkadaşlarını Davet Et", "Size özel kod: FASHION2024"),
                  ]),
                  const SizedBox(height: 40),
                  _buildLogoutButton(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text("PROFİL"),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF2F2F7), width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFF2F2F7),
                          backgroundImage: _profileImage != null 
                              ? FileImage(_profileImage!) 
                              : (user?.photoURL != null && user!.photoURL!.isNotEmpty
                                  ? (user!.photoURL!.startsWith('http')
                                      ? NetworkImage(user!.photoURL!) as ImageProvider
                                      : FileImage(File(user!.photoURL!.startsWith('file') 
                                          ? Uri.parse(user!.photoURL!).toFilePath() 
                                          : user!.photoURL!)))
                                  : null),
                          child: (_profileImage == null && (user?.photoURL == null || user!.photoURL!.isEmpty))
                               ? const Icon(Icons.person, size: 60, color: Colors.black26)
                               : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF121212), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  user?.displayName ?? 'Moda Tutkunu',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "SILVER MEMBER",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Row(
      children: [
        _buildStatItem("$_savedCount", "Kaydedilen"),
        _buildStatItem("%$_avgScore", "Stil Uyumu"),
        _buildStatItem("$_analysisCount", "Analizler"),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black54),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: () => _handleMenuTap(context, title),
    );
  }

  void _handleMenuTap(BuildContext context, String title) {
    switch (title) {
      case "Hesap Bilgileri":
        _showAccountDialog(context);
        break;
      case "Bildirimler":
        _showNotificationToggle(context);
        break;
      case "Güvenlik":
        _showSecurityDialog(context);
        break;
      case "Stil Analitiği":
        _showAnalyticsDialog(context);
        break;
      case "Moda Kulübü":
        _showClubDialog(context);
        break;
      case "Arkadaşlarını Davet Et":
        _showInviteDialog(context);
        break;
    }
  }

  void _showAccountDialog(BuildContext context) {
    final nameController = TextEditingController(text: user?.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hesap Bilgileri"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Ad Soyad"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              await user?.updateDisplayName(nameController.text);
              if (mounted) {
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  void _showNotificationToggle(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bildirim ayarları güncellendi.")),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Güvenlik"),
        content: const Text("Şifre sıfırlama e-postası gönderilsin mi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hayır")),
          TextButton(
            onPressed: () {
              if (user?.email != null) {
                FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("E-posta gönderildi.")));
              }
            },
            child: const Text("Evet"),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Stil Analitiği"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text("En sevilen tarz: Klasik")),
            ListTile(leading: Icon(Icons.trending_up, color: Colors.blue), title: Text("Stil puanı: 85/100")),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kapat"))],
      ),
    );
  }

  void _showClubDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Moda Kulübü"),
        content: const Text("Silver Member olduğunuz için tüm analizler %20 daha hızlı!"),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Harika!"))],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Davet Et"),
        content: const Text("Kodunuz: FASHION2024\nPaylaşarak 80₺ kredi kazanın."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kopyala"))],
      ),
    );
  }

  Widget _buildMembershipSection() {
    final advantages = [
      {'title': 'SILVER MEMBER', 'desc': '%10 İndirim Aktif', 'color': Color(0xFF121212)},
      {'title': 'TREND ANALİZİ', 'desc': 'Kişiye Özel Rapor', 'color': Color(0xFF8E8E93)},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: advantages.length,
        itemBuilder: (context, i) {
          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: advantages[i]['color'] as Color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  advantages[i]['title'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(
                  advantages[i]['desc'] as String,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        child: const Text("OTURUMU KAPAT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}
