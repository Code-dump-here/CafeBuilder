/// Mirror of what the file API actually accepts.
///
/// Source of truth: `GcsFileStorageService.UploadAsync`
/// (SmartCoffeeBuilder.Service/Implementations/GcsFileStorageService.cs:28-87)
///   - image endpoint   POST /api/files/images -> imageExtensions only
///   - general endpoint POST /api/files        -> imageExtensions + documentExtensions
///   - size cap         Gcs:MaxFileSizeMb, default 10
///
/// The server matches on FILE EXTENSION, not MIME type. That matters here
/// because `FileType.image` in file_picker maps to the platform's own idea of
/// an image — which on iOS includes .heic for every photo taken on a modern
/// iPhone, and on Android can include .bmp and .webp variants the server does
/// not list. Picking with `FileType.custom` + [allowedExtensions] makes the
/// picker itself refuse what the upload would refuse later.
library;

const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

/// No video, of any kind — the API accepts none.
const List<String> documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];

List<String> get allUploadExtensions => [
  ...imageExtensions,
  ...documentExtensions,
];

/// Keep in step with `Gcs:MaxFileSizeMb` (appsettings is gitignored; default 10).
const int maxUploadSizeMb = 10;
const int maxUploadSizeBytes = maxUploadSizeMb * 1024 * 1024;

/// Returns a user-facing message when [name]/[sizeBytes] would be rejected by
/// the server, or null when the file is acceptable.
///
/// `allowedExtensions` on the picker is not enough on its own: some platforms
/// let the user switch to "All files", and a file shared into the app from
/// another application never passes through the picker at all.
String? validateUpload({
  required String name,
  required int sizeBytes,
  bool imageOnly = false,
}) {
  if (sizeBytes <= 0) return 'That file is empty.';

  if (sizeBytes > maxUploadSizeBytes) {
    final mb = (sizeBytes / 1024 / 1024).toStringAsFixed(1);
    return 'That file is ${mb}MB. The limit is ${maxUploadSizeMb}MB.';
  }

  final dot = name.lastIndexOf('.');
  final extension = dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  final allowed = imageOnly ? imageExtensions : allUploadExtensions;

  if (!allowed.contains(extension)) {
    return '.$extension files are not supported. '
        'Allowed: ${allowed.map((e) => '.$e').join(', ')}.';
  }

  return null;
}
