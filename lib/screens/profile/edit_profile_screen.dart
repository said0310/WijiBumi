import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/smart_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const List<String> _genderOptions = [
    'Laki-laki',
    'Perempuan',
    'Tidak ingin menyebutkan',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;

  late final String _initialName;
  late final String _initialEmail;
  late final String _initialPhone;
  late final String? _initialAvatarUrl;
  late final DateTime? _initialBirthDate;
  late final String? _initialGender;

  Uint8List? _pickedAvatarBytes;
  String? _pickedAvatarName;
  String? _currentAvatarUrl;
  bool _avatarRemoved = false;
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _initialName = (user?.fullName ?? '').trim();
    _initialEmail = (user?.email ?? '').trim();
    _initialPhone = (user?.phone ?? '').trim();
    _initialAvatarUrl =
        (user?.avatarPath != null && user!.avatarPath!.trim().isNotEmpty)
            ? user.avatarPath
            : null;
    _initialBirthDate = user?.birthDate;
    _initialGender =
        user?.gender != null && _genderOptions.contains(user!.gender)
            ? user.gender
            : null;

    _nameController = TextEditingController(text: _initialName);
    _emailController = TextEditingController(text: _initialEmail);
    _phoneController = TextEditingController(text: _initialPhone);
    _selectedBirthDate = _initialBirthDate;
    _birthDateController = TextEditingController(
      text: _selectedBirthDate != null
          ? DateFormatter.formatBirthDate(_selectedBirthDate!)
          : '',
    );
    _currentAvatarUrl = _initialAvatarUrl;
    _selectedGender = _initialGender;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().refreshVerificationStatus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? _validateName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Nama tidak boleh kosong';
    if (trimmed.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validateIndonesianPhone(String? value) {
    return validateIndonesianPhoneNumber(
      value,
      emptyMessage: 'Nomor HP tidak boleh kosong',
      invalidMessage:
          'Masukkan nomor HP Indonesia yang valid (contoh: 081234567890 atau +6281234567890)',
    );
  }

  bool get _hasAvatarPreview =>
      _pickedAvatarBytes != null ||
      (!_avatarRemoved &&
          _currentAvatarUrl != null &&
          _currentAvatarUrl!.isNotEmpty);

  bool get _hasChanges {
    final avatarChanged = _pickedAvatarBytes != null ||
        (_avatarRemoved && _initialAvatarUrl != null);
    return _nameController.text.trim() != _initialName ||
        _emailController.text.trim() != _initialEmail ||
        _phoneController.text.trim() != _initialPhone ||
        !_isSameDay(_selectedBirthDate, _initialBirthDate) ||
        _selectedGender != _initialGender ||
        avatarChanged;
  }

  bool get _isFormValidForSave {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birthDateValid =
        _selectedBirthDate == null || !_selectedBirthDate!.isAfter(today);
    return _validateName(_nameController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validateIndonesianPhone(_phoneController.text) == null &&
        birthDateValid;
  }

  bool get _canSave => !_isLoading && _hasChanges && _isFormValidForSave;

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedAvatarBytes = bytes;
          _pickedAvatarName = picked.name;
          _avatarRemoved = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat mengakses foto: $e')),
      );
    }
  }

  void _resetAvatar() {
    setState(() {
      _pickedAvatarBytes = null;
      _pickedAvatarName = null;
      _currentAvatarUrl = null;
      _avatarRemoved = true;
    });
  }

  void _showPhotoPickerOptions() {
    showGlassBottomSheet(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah Foto Profil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Ambil Foto dengan Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            if (_hasAvatarPreview)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Hapus / Reset Foto Profil',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _resetAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(1920, 1, 1);
    final fallbackDate = DateTime(now.year - 20, now.month, now.day);
    DateTime initial = _selectedBirthDate ?? fallbackDate;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(today)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (ctx, child) {
        final baseTheme = Theme.of(ctx);
        final isDark = baseTheme.brightness == Brightness.dark;
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: isDark ? AppColors.primaryLight : AppColors.forestGreen,
              onPrimary: isDark ? Colors.black : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = DateTime(picked.year, picked.month, picked.day);
        _birthDateController.text =
            DateFormatter.formatBirthDate(_selectedBirthDate!);
      });
    }
  }

  Future<void> _handleCancel() async {
    if (_isLoading) return;
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }
    final discard = await showGlassConfirmDialog(
      context,
      title: 'Batalkan Perubahan?',
      message:
          'Anda memiliki perubahan data profil yang belum disimpan. Keluar tanpa menyimpan?',
      cancelText: 'Lanjutkan Edit',
      confirmText: 'Keluar',
      confirmColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
    );
    if (discard && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveProfile() async {
    if (!_canSave) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? uploadedAvatarUrl = _avatarRemoved ? null : _currentAvatarUrl;
    if (_pickedAvatarBytes != null) {
      final url = await SupabaseService.instance.uploadImageBytes(
        bytes: _pickedAvatarBytes!,
        bucket: 'avatars',
        fileName: _pickedAvatarName ?? 'avatar.jpg',
      );
      if (!mounted) return;
      if (url == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal mengunggah foto profil. Periksa koneksi lalu coba lagi.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      uploadedAvatarUrl = url;
    }

    if (!mounted) return;
    final res = await context.read<AuthProvider>().updateProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          avatarPath: uploadedAvatarUrl,
          removeAvatar: _avatarRemoved && _pickedAvatarBytes == null,
          birthDate: _selectedBirthDate,
          clearBirthDate: _selectedBirthDate == null,
          gender: _selectedGender,
          clearGender: _selectedGender == null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      final msg =
          res.emailVerificationSent && SupabaseService.instance.isConnected
              ? 'Profil diperbarui! Cek email baru Anda untuk konfirmasi perubahan email.'
              : 'Profil berhasil diperbarui!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Gagal menyimpan perubahan profil.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final verification = authProvider.getProfileVerificationStatus(
      draftEmail: _emailController.text,
      draftPhone: _phoneController.text,
    );
    final emailVerified = verification['emailVerified'] == true;
    final phoneVerified = verification['phoneVerified'] == true;
    final pendingEmail = verification['pendingEmail'] as String?;

    final mutedTextColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final sectionBorderColor =
        isDark ? AppColors.borderDark : AppColors.softSage;

    return PopScope(
      canPop: !_hasChanges && !_isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleCancel();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.warmIvory,
        appBar: AppBar(
          title: const Text('Edit Profil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            onPressed: _handleCancel,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Avatar & Actions Section
                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      tintColor: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.9)
                          : AppColors.paleMint.withValues(alpha: 0.72),
                      border: Border.all(color: sectionBorderColor),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showPhotoPickerOptions,
                            child: Stack(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.warmIvory,
                                    border: Border.all(
                                      color: AppColors.secondaryEmerald
                                          .withValues(alpha: 0.5),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _hasAvatarPreview
                                        ? SmartImage(
                                            memoryBytes: _pickedAvatarBytes,
                                            source: _currentAvatarUrl,
                                            fit: BoxFit.cover,
                                            fallback: _DefaultAvatarPlaceholder(
                                              isDark: isDark,
                                            ),
                                          )
                                        : _DefaultAvatarPlaceholder(
                                            isDark: isDark,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.primaryLight
                                          : AppColors.forestGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            children: [
                              TextButton(
                                onPressed: _showPhotoPickerOptions,
                                child: const Text('Ganti Foto Profil'),
                              ),
                              if (_hasAvatarPreview)
                                TextButton(
                                  onPressed: _resetAvatar,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: const Text('Hapus Foto'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Identitas Pribadi Section
                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      tintColor: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.9),
                      border: Border.all(color: sectionBorderColor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Pribadi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.forestGreen,
                            ),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama lengkap Anda',
                            controller: _nameController,
                            prefixIcon: const Icon(Icons.person_outline),
                            onChanged: (_) => setState(() {}),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Tanggal Lahir (Opsional)',
                            hint: 'Pilih tanggal lahir',
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: _pickBirthDate,
                            prefixIcon: const Icon(Icons.cake_outlined),
                            suffixIcon: _selectedBirthDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    tooltip: 'Hapus tanggal lahir',
                                    onPressed: () {
                                      setState(() {
                                        _selectedBirthDate = null;
                                        _birthDateController.clear();
                                      });
                                    },
                                  )
                                : const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Jenis Kelamin (Opsional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_selectedGender),
                            initialValue: _selectedGender,
                            isExpanded: true,
                            hint: const Text('Pilih jenis kelamin'),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.wc_outlined),
                              suffixIcon: _selectedGender != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      tooltip: 'Hapus pilihan jenis kelamin',
                                      onPressed: () {
                                        setState(() => _selectedGender = null);
                                      },
                                    )
                                  : null,
                            ),
                            items: _genderOptions
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(
                                      option,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedGender = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kontak & Status Verifikasi Section
                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      tintColor: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.9),
                      border: Border.all(color: sectionBorderColor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kontak & Verifikasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.forestGreen,
                            ),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Email',
                            labelTrailing: _VerificationBadge(
                              isVerified: emailVerified,
                            ),
                            hint: 'email@domain.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            onChanged: (_) => setState(() {}),
                            validator: _validateEmail,
                          ),
                          if (pendingEmail != null &&
                              pendingEmail.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Menunggu konfirmasi email baru: $pendingEmail',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (SupabaseService.instance.isConnected) ...[
                            const SizedBox(height: 6),
                            Text(
                              emailVerified
                                  ? 'Perubahan email akan mengirim tautan verifikasi baru melalui Supabase Auth.'
                                  : 'Email belum terverifikasi. Simpan perubahan atau cek kotak masuk email Anda untuk konfirmasi.',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedTextColor,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Text(
                              'Verifikasi email dilakukan melalui Supabase Auth saat terhubung ke server.',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Nomor WhatsApp / HP',
                            labelTrailing: _VerificationBadge(
                              isVerified: phoneVerified,
                            ),
                            hint: '081234567890',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            onChanged: (_) => setState(() {}),
                            validator: _validateIndonesianPhone,
                          ),
                          if (!phoneVerified) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Nomor HP mengikuti status verifikasi server (belum terverifikasi).',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Batal',
                            isOutlined: true,
                            onPressed: _isLoading ? null : _handleCancel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: 'Simpan Perubahan',
                            isLoading: _isLoading,
                            onPressed: _canSave ? _saveProfile : null,
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultAvatarPlaceholder extends StatelessWidget {
  final bool isDark;

  const _DefaultAvatarPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.paleMint,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: 42,
        color: isDark ? AppColors.primaryLight : AppColors.forestGreen,
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;

  const _VerificationBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isVerified
        ? (isDark ? AppColors.primaryLight : AppColors.primary)
        : AppColors.warning;
    final bgColor = isVerified
        ? AppColors.emeraldGreen.withValues(alpha: 0.14)
        : AppColors.warning.withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_outlined : Icons.info_outline,
            size: 12,
            color: fgColor,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
