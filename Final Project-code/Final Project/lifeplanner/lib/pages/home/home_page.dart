import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lifeplanner/pages/home/chat_bot.dart';
import 'package:lifeplanner/pages/home/finance_page.dart';
import 'package:lifeplanner/pages/home/health_page.dart';
import 'package:lifeplanner/pages/home/schedule_page.dart';
import 'package:lifeplanner/pages/settings/settings_page.dart';
import 'package:lifeplanner/widgets/note_cta_widget.dart';
import 'package:lifeplanner/widgets/weather_disable_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:lifeplanner/utils/network_status_service.dart';
import 'package:lifeplanner/widgets/custom_bottom_nav_bar.dart';
import 'package:lifeplanner/widgets/quote_widget.dart';
import 'package:lifeplanner/widgets/today_banner.dart';
import 'package:lifeplanner/widgets/weather_banner.dart';

// <-- import your BaseScaffold
import 'package:lifeplanner/widgets/base_scaffold.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const List<Map<String, String>> fallbackQuotes = [
  {
    'quote': 'Believe you can and you’re halfway there.',
    'author': 'Theodore Roosevelt',
  },
  {
    'quote': 'Strive not to be a success, but rather to be of value.',
    'author': 'Albert Einstein',
  },
  {
    'quote':
        'Your time is limited, so don’t waste it living someone else’s life.',
    'author': 'Steve Jobs',
  },
  {
    'quote': 'The only way to do great work is to love what you do.',
    'author': 'Steve Jobs',
  },
  {
    'quote':
        'Success is not final, failure is not fatal: it is the courage to continue that counts.',
    'author': 'Winston Churchill',
  },
  {'quote': 'What we think, we become.', 'author': 'Buddha'},
  {
    'quote': 'Act as if what you do makes a difference. It does.',
    'author': 'William James',
  },
  {'quote': 'The best revenge is massive success.', 'author': 'Frank Sinatra'},
  {
    'quote': 'You miss 100% of the shots you don’t take.',
    'author': 'Wayne Gretzky',
  },
  {
    'quote': 'Whether you think you can or you think you can’t, you’re right.',
    'author': 'Henry Ford',
  },
  {
    'quote': 'I have not failed. I’ve just found 10,000 ways that won’t work.',
    'author': 'Thomas A. Edison',
  },
  {
    'quote': 'It does not matter how slowly you go as long as you do not stop.',
    'author': 'Confucius',
  },
  {
    'quote': 'Everything you’ve ever wanted is on the other side of fear.',
    'author': 'George Addair',
  },
  {'quote': 'Dream big and dare to fail.', 'author': 'Norman Vaughan'},
  {
    'quote':
        'Hardships often prepare ordinary people for an extraordinary destiny.',
    'author': 'C.S. Lewis',
  },
];

WeatherData? _cachedWeather;
DateTime? _lastWeatherFetchTime;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 2;
  String? _quote, _author;
  late final NetworkStatusNotifier _netStatus;
  Timer? _weatherTimer;
  static const _weatherApiKey = 'UR_API_KEY_HERE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _netStatus = Provider.of<NetworkStatusNotifier>(context, listen: false);
    _netStatus.addListener(_onNetworkChange);
    _loadDailyQuote();
    _startWeatherUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weatherTimer?.cancel();
    _netStatus.removeListener(_onNetworkChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _netStatus.isOnline) {
      setState(() {});
    }
  }

  void _onNetworkChange() {
    if (_netStatus.isOnline) {
      _loadDailyQuote();
      setState(() {});
    }
  }

  void _startWeatherUpdates() {
    _weatherTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (_netStatus.isOnline && mounted) setState(() {});
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('App Tips'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• For the best experience, keep your device online.'),
                SizedBox(height: 8),
                Text('• You’ll see daily motivational quotes.'),
                SizedBox(height: 8),
                Text('• Live weather updates depend on internet access.'),
                SizedBox(height: 8),
                Text(
                  '• Use the tabs below to explore schedule, chatbot, and more.',
                ),
                SizedBox(height: 8),
                Text('• Tap the settings icon to customize your preferences.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _loadDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final storedDate = prefs.getString('dailyQuoteDate');
    final storedQ = prefs.getString('dailyQuoteText');
    final storedA = prefs.getString('dailyQuoteAuthor');
    final wasFallback = prefs.getBool('dailyQuoteIsFallback') ?? false;

    Future<void> fetchNewQuote() async {
      try {
        final res = await http.get(Uri.parse('https://favqs.com/api/qotd'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final body = data['quote'];
          final text = body['body'] as String;
          final author = body['author'] as String;

          await prefs.setString('dailyQuoteDate', today);
          await prefs.setString('dailyQuoteText', text);
          await prefs.setString('dailyQuoteAuthor', author);
          await prefs.setBool('dailyQuoteIsFallback', false);

          setState(() {
            _quote = text;
            _author = author;
          });
        }
      } catch (_) {}
    }

    if (storedDate == today && storedQ != null && storedA != null) {
      setState(() {
        _quote = storedQ;
        _author = storedA;
      });
      if (wasFallback && _netStatus.isOnline) await fetchNewQuote();
    } else if (_netStatus.isOnline) {
      await fetchNewQuote();
    } else {
      final fb = fallbackQuotes[Random().nextInt(fallbackQuotes.length)];
      await prefs.setString('dailyQuoteDate', today);
      await prefs.setString('dailyQuoteText', fb['quote']!);
      await prefs.setString('dailyQuoteAuthor', fb['author']!);
      await prefs.setBool('dailyQuoteIsFallback', true);

      setState(() {
        _quote = fb['quote'];
        _author = fb['author'];
      });
    }
  }

  String getWeatherQuote(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('sunny')) {
      return 'Shine like the sun even on your toughest days.';
    }
    if (cond.contains('rain')) return 'Storms don’t last forever. Keep going.';
    if (cond.contains('cloud')) return 'Behind every cloud is a silver lining.';
    if (cond.contains('snow')) {
      return 'Even the coldest days bring their own beauty.';
    }
    if (cond.contains('wind')) {
      return 'Let the wind push you forward, not hold you back.';
    }
    return 'Embrace every season of life with courage.';
  }

  Future<WeatherData> _fetchLiveWeather(Map<String, dynamic> loc) async {
    if (_cachedWeather != null && _lastWeatherFetchTime != null) {
      final diff = DateTime.now().difference(_lastWeatherFetchTime!);
      if (diff < const Duration(minutes: 30)) return _cachedWeather!;
    }

    final url =
        (loc['lat'] != null && loc['lon'] != null)
            ? 'https://api.weatherapi.com/v1/current.json?key=$_weatherApiKey&q=${loc['lat']},${loc['lon']}&aqi=no'
            : 'https://api.weatherapi.com/v1/current.json?key=$_weatherApiKey&q=${Uri.encodeComponent(loc['city'] as String)}&aqi=no';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Weather API error: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    final current = json['current'];
    final data = WeatherData(
      tempC: current['temp_c']?.toDouble() ?? 0.0,
      feelsLikeC: current['feelslike_c']?.toDouble() ?? 0.0,
      description: current['condition']['text'] ?? 'Unknown',
      iconUrl: 'https:${current['condition']['icon']}',
      quote: getWeatherQuote(current['condition']['text']),
    );
    _cachedWeather = data;
    _lastWeatherFetchTime = DateTime.now();
    return data;
  }

  void _onItemTapped(int idx) {
    if (idx == _selectedIndex) return;
    setState(() => _selectedIndex = idx);

    late final Widget page;
    switch (idx) {
      case 0:
        page = const SchedulePage();
        break;
      case 1:
        page = const FinancePage();
        break;
      case 3:
        page = const HealthPage();
        break;
      case 4:
        page = const ChatbotPage();
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => setState(() => _selectedIndex = 2));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCD7D),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showHelpDialog,
        ),
        title: const Text('HOME'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (_quote != null && _author != null)
              QuoteCard(
                quote: _quote!,
                author: _author!,
                imageAsset: 'assets/img/motivation.png',
              ),
            const TodayBanner(),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('settings')
                      .doc('preferences')
                      .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return _netStatus.isOnline
                      ? const WeatherDisabledBanner() // <-- fixed
                      : const WeatherDisabledBanner(
                        message: 'Weather is unavailable while offline.',
                      ); // <-- fixed
                }
                final data = snap.data!.data() as Map<String, dynamic>;
                final show = data['showWeather'] as bool? ?? false;
                if (!show) return const WeatherDisabledBanner(); // <-- fixed
                final loc = data['weatherLocation'] as Map<String, dynamic>?;
                return FutureBuilder<WeatherData>(
                  future: _fetchLiveWeather(loc!),
                  builder: (ctx2, snap2) {
                    if (snap2.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap2.hasError || snap2.data == null) {
                      return _netStatus.isOnline
                          ? const WeatherDisabledBanner() // <-- fixed
                          : const WeatherDisabledBanner(
                            message:
                                'Unable to fetch weather data while offline.',
                          );
                    }
                    final wd = snap2.data!;
                    return WeatherBanner(
                      tempC: wd.tempC,
                      feelsLikeC: wd.feelsLikeC,
                      description: wd.description,
                      iconUrl: wd.iconUrl,
                      quote: wd.quote,
                    );
                  },
                );
              },
            ),
            const NoteCTAWidget(),
          ],
        ),
      ),
    );
  }
}

class WeatherData {
  final double tempC;
  final double feelsLikeC;
  final String description;
  final String iconUrl;
  final String quote;

  WeatherData({
    required this.tempC,
    required this.feelsLikeC,
    required this.description,
    required this.iconUrl,
    required this.quote,
  });
}
