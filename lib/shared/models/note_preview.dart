class NotePreview {
  const NotePreview({
    required this.title,
    required this.summary,
    required this.tag,
    required this.accentHex,
    required this.collaborators,
    required this.updatedLabel,
  });

  final String title;
  final String summary;
  final String tag;
  final int accentHex;
  final List<String> collaborators;
  final String updatedLabel;
}

const sampleNotes = [
  NotePreview(
    title: 'Audit gudang mingguan',
    summary: 'Stok masuk, foto rak, dan hasil scan dokumen penerimaan.',
    tag: 'Kolab',
    accentHex: 0xFF0D9488,
    collaborators: ['AF', 'DN', '+3'],
    updatedLabel: '10 menit lalu',
  ),
  NotePreview(
    title: 'Rencana sprint produk',
    summary: 'Checklist prioritas, risiko integrasi, dan ringkasan meeting.',
    tag: 'Markdown',
    accentHex: 0xFF2563EB,
    collaborators: ['AF', 'MI'],
    updatedLabel: '1 jam lalu',
  ),
  NotePreview(
    title: 'OCR label mesin A-104',
    summary: 'Teks hasil kamera sudah disisipkan ke logbook inspeksi.',
    tag: 'OCR',
    accentHex: 0xFFF97316,
    collaborators: ['AF'],
    updatedLabel: 'Kemarin',
  ),
];
