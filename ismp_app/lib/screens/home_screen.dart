import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/blog.dart';
import '../services/firebase_service.dart';
import '../models/team_member.dart';
import '../models/mock_data/events_mock.dart';
import '../models/profile_data.dart';
import 'core_team_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'dev_team_screen.dart';
import 'notifications_screen.dart';
import 'moments_screen.dart';
import 'blogs_screen.dart';
import 'attendance_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentCarouselIndex = 0;

  String _getEventsSubtitle() {
    final now = DateTime.now();
    final oneHourFromNow = now.add(const Duration(hours: 1));
    bool upcoming = false;
    
    for (var eventList in eventsData.values) {
      for (var event in eventList) {
        final eventTime = event.getParsedDateTime();
        if (eventTime.isAfter(now) && eventTime.isBefore(oneHourFromNow)) {
          return '${event.title} starts soon!';
        } else if (eventTime.year == now.year && eventTime.month == now.month && eventTime.day == now.day && eventTime.isAfter(now)) {
          upcoming = true;
        }
      }
    }
    return upcoming ? 'You have events scheduled later today.' : 'See what is happening today.';
  }

  List<Widget> _buildCarouselCards(BuildContext context) {
    final mentor = dummyUser.mentor;
    final List<_QuickLink> links = [
      _QuickLink(
        title: 'App Developers',
        subtitle: 'Meet the team behind\nthe ISMP app.',
        icon: Icons.code,
        bgImage: 'assets/images/carousel/dev_team_poster.png',
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3E52), Color(0xFF041923)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: const Color(0xFF4A3AFF),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevTeamScreen())),
      ),
      _QuickLink(
        title: mentor?.name ?? 'Mentor Profile',
        subtitle: 'We mentor. We guide.\nWe grow together.',
        icon: Icons.person,
        bgImage: 'assets/images/carousel/mentor_poster.png',
        gradient: const LinearGradient(
          colors: [Color(0xFF2B165C), Color(0xFF140733)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: const Color(0xFF00FFCC),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      _QuickLink(
        title: "Today's Events",
        subtitle: _getEventsSubtitle(),
        icon: Icons.event,
        bgImage: 'assets/images/carousel/events_poster.png',
        gradient: const LinearGradient(
          colors: [Color(0xFF561541), Color(0xFF27061C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: const Color(0xFFFFB020),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
      ),
    ];

    return links.map((link) {
      return GestureDetector(
        onTap: link.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: link.color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: link.color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-bleed background image
                Image.asset(
                  link.bgImage,
                  fit: BoxFit.cover,
                ),
                // Gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Content on the left
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 180,
                        child: Text(
                          link.subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2B124C), // Shiny Purple
              Color(0xFF0F0F13), // Midnight Dark
              Color(0xFF1E103C), // Deep Indigo
              Color(0xFF0F0F13), // Midnight Dark
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildCoreTeam(),
              _buildMomentsHeader(context),
              _buildMomentsList(),
              _buildBlogsHeader(context),
              _buildLatestBlog(),
              _buildAboutISMP(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF15111E),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2B124C),
              Color(0xFF15111E),
              Color(0xFF1E103C),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3AFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4A3AFF).withOpacity(0.4)),
                      ),
                      child: const Text(
                        'ISMP',
                        style: TextStyle(
                          color: Color(0xFF00FFCC),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Navigate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quick access to all pages',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 8),
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _drawerItem(
                      icon: Icons.group_outlined,
                      label: 'Core Team',
                      subtitle: 'Meet the ISMP mentors',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CoreTeamScreen()));
                      },
                    ),
                    _drawerItem(
                      customIcon: const Text(
                        '</>',
                        style: TextStyle(
                          color: Color(0xFF00FFCC),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      label: 'App Developers',
                      subtitle: 'The team behind the app',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DevTeamScreen()));
                      },
                    ),
                    _drawerItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      subtitle: 'Upcoming activities & sessions',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                      },
                    ),
                    _drawerItem(
                      icon: Icons.article_outlined,
                      label: 'Blogs',
                      subtitle: 'Read campus stories & guides',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogsScreen()));
                      },
                    ),
                    _drawerItem(
                      icon: Icons.photo_library_outlined,
                      label: 'Moments',
                      subtitle: 'Photo memories from campus',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentsScreen()));
                      },
                    ),
                    _drawerItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      subtitle: 'Alerts & announcements',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      },
                    ),
                    _drawerItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      subtitle: 'Track your sessions',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                      },
                    ),
                    _drawerItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      subtitle: 'Your mentor & info',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                    ),
                  ],
                ),
              ),
              // Footer
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'IIT Ropar ISMP v1.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    IconData? icon,
    Widget? customIcon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A3AFF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4A3AFF).withOpacity(0.2)),
          ),
          child: customIcon ?? Icon(icon, color: const Color(0xFF00FFCC), size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  Widget _buildMomentsHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Moments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentsScreen()));
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  color: Color(0xFF4A3AFF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentsList() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _momentCard('https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=500&q=80', 'Batch Meetup'),
            _momentCard('https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=500&q=80', 'Auditorium'),
            _momentCard('https://images.unsplash.com/photo-1511629091441-ee46146481b6?w=500&q=80', 'Hostel Night'),
            _momentCard('https://images.unsplash.com/photo-1523580494112-071d16940d14?w=500&q=80', 'Campus Tour'),
          ],
        ),
      ),
    );
  }

  Widget _momentCard(String imageUrl, String title) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(12),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBlogsHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Latest Blog',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogsScreen()));
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  color: Color(0xFF4A3AFF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestBlog() {
    return StreamBuilder<List<BlogPost>>(
      stream: FirebaseService.instance.streamBlogPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFF4A3AFF)),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }
        final posts = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverToBoxAdapter(
            child: _BlogCard(post: posts.first),
          ),
        );
      },
    );
  }

  Widget _buildAboutISMP() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About ISMP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ISMP is a student-run mentorship program dedicated to helping freshers transition smoothly into campus life. We provide guidance, support, and a welcoming community.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreTeam() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                const Text(
                  'ISMP Core Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CoreTeamScreen()),
                    );
                  },
                  child: const Text(
                    'View All →',
                    style: TextStyle(
                      color: Color(0xFF4A3AFF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.05, curve: Curves.easeOutQuad),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: coreTeamMembers.length,
              itemBuilder: (context, index) {
                return _teamMemberCard(coreTeamMembers[index])
                    .animate()
                    .fadeIn(duration: 800.ms, delay: (index * 100).ms)
                    .slideY(begin: 0.15, curve: Curves.easeOutQuad)
                    .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutQuad);
              },
            ),
          ),
          const SizedBox(height: 24),
          CarouselSlider(
            options: CarouselOptions(
              height: 180.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            items: _buildCarouselCards(context),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildCarouselCards(context).asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentCarouselIndex == entry.key
                      ? const Color(0xFF00FFCC)
                      : Colors.white.withOpacity(0.2),
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 800.ms, delay: 300.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showBioDialog(BuildContext context, TeamMember member) {
    if (member.bio == null || member.bio!.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF15151A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFF00FFCC).withOpacity(0.3)),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(member.image),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.role,
                      style: const TextStyle(
                        color: Color(0xFF00FFCC),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Text(
            member.bio!,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF00FFCC)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _teamMemberCard(TeamMember member) {
    bool isFaculty = member.role.contains('FACULTY');
    return GestureDetector(
      onTap: () => _showBioDialog(context, member),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 45),
              padding: const EdgeInsets.fromLTRB(8, 82, 8, 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.role.toUpperCase(),
                    style: TextStyle(
                      color: isFaculty ? const Color(0xFF00FFCC) : const Color(0xFFB4B0FF),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isFaculty
                      ? [const Color(0xFF00FFCC), const Color(0xFF00FFCC).withOpacity(0.1)]
                      : [const Color(0xFF4A3AFF), const Color(0xFF00FFCC).withOpacity(0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFaculty ? const Color(0xFF00FFCC) : const Color(0xFF4A3AFF)).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundImage: AssetImage(member.image),
                backgroundColor: const Color(0xFF15151A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C23),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: post.tag.color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TagBadge(tag: post.tag),
                  const Spacer(),
                  Text(
                    '${post.readMinutes} min read',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: post.tag.color.withOpacity(0.25),
                    child: Text(
                      post.author[0],
                      style: TextStyle(
                        color: post.tag.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    post.date,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _BlogDetailScreen(post: post)),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.tag});
  final BlogTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tag.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tag.color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          color: tag.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BlogDetailScreen extends StatelessWidget {
  const _BlogDetailScreen({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _TagBadge(tag: post.tag),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: post.tag.color.withOpacity(0.25),
                  child: Text(
                    post.author[0],
                    style: TextStyle(
                      color: post.tag.color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${post.date}  ·  ${post.readMinutes} min read',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 24),
            Text(
              post.content,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 15,
                height: 1.75,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String bgImage;
  final LinearGradient gradient;
  final Color color;
  final VoidCallback onTap;

  _QuickLink({
    required this.title,
    required this.subtitle,
    this.icon,
    required this.bgImage,
    required this.gradient,
    required this.color,
    required this.onTap,
  });
}
