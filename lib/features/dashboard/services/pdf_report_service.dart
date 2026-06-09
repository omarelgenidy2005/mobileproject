import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../../data/models/active_workout_session.dart';

class PdfReportService {
  static Future<void> generateMonthlyReport(List<ActiveWorkoutSession> sessions) async {
    final now = DateTime.now();
    // Filter sessions for the current month
    final currentMonthSessions = sessions.where((s) => 
      s.startedAt.year == now.year && s.startedAt.month == now.month
    ).toList();
    
    // Sort chronologically
    currentMonthSessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final doc = pw.Document();
    
    final monthName = DateFormat('MMMM yyyy').format(now);
    
    double totalVolumeForMonth = 0;
    
    final tableData = <List<String>>[
      ['Date', 'Workout', 'Weight Moved (kg)']
    ];
    
    for (var session in currentMonthSessions) {
      final dateStr = DateFormat('MMM d, yyyy').format(session.startedAt);
      final volume = session.totalVolumeKg;
      totalVolumeForMonth += volume;
      
      tableData.add([
        dateStr,
        session.title,
        volume.toStringAsFixed(1),
      ]);
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Monthly Workout Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Month: $monthName', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Total Workouts: ${currentMonthSessions.length}', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Total Weight Moved: ${totalVolumeForMonth.toStringAsFixed(1)} kg', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              if (currentMonthSessions.isEmpty)
                pw.Text('No workouts recorded for this month.')
              else
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
            ],
          );
        },
      ),
    );

    // This will open a preview/print/share dialog natively
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Workout_Report_$monthName.pdf'.replaceAll(' ', '_'),
    );
  }
}
