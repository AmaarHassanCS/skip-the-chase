import 'package:flutter/material.dart';
import 'package:skip_the_chase/models/match.dart';
import 'package:skip_the_chase/screens/chat_screen.dart';
import 'package:skip_the_chase/services/match_service.dart';
import 'package:skip_the_chase/widgets/match_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _matchService = MatchService();
  final _supabase = Supabase.instance.client;
  
  List<Match> _matches = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    if (_supabase.auth.currentUser == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _matches = await _matchService.getMatches(_supabase.auth.currentUser!.id);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load matches: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(Match match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(match: match),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Messages'),
            Tab(text: 'New Matches'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Messages tab
                    _matches.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                            itemCount: _matches.length,
                            itemBuilder: (context, index) {
                              final match = _matches[index];
                              if (match.lastMessage != null) {
                                return MatchCard(
                                  match: match,
                                  onTap: () => _navigateToChat(match),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                    
                    // New Matches tab
                    _matches.isEmpty
                        ? const Center(child: Text('No new matches'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _matches.where((m) => m.lastMessage == null).length,
                            itemBuilder: (context, index) {
                              final newMatches = _matches.where((m) => m.lastMessage == null).toList();
                              return GestureDetector(
                                onTap: () => _navigateToChat(newMatches[index]),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: newMatches[index].matchedUser.avatarUrl != null
                                            ? Image.network(
                                                newMatches[index].matchedUser.avatarUrl!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              )
                                            : Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.person, size: 50),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      newMatches[index].matchedUser.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('${newMatches[index].matchedUser.age} years'),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
    );
  }
}