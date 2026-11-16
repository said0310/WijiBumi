import 'package:flutter/foundation.dart' hide Category;
import '../models/product.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  int _fetchSeq = 0;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<Product> get recommendedProducts => _products.take(4).toList();

  ProductProvider() {
    initData();
  }

  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await SupabaseService.instance.getCategories();
      await fetchProducts();
    } catch (e) {
      debugPrint('Error init product data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProducts() async {
    final seq = ++_fetchSeq;
    try {
      final fetched = await SupabaseService.instance.getProducts(
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
      );
      if (seq != _fetchSeq) return;
      _products = fetched;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    fetchProducts();
  }

  void selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // Toggle back to all
    } else {
      _selectedCategoryId = categoryId;
    }
    fetchProducts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchProducts();
  }

  void clearSearch() {
    _searchQuery = '';
    fetchProducts();
  }

  void resetFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    fetchProducts();
  }
}
