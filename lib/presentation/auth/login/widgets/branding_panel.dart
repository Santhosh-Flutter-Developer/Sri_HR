import 'package:flutter/material.dart';

class BrandingPanel extends StatelessWidget {
  const BrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Padding(
      padding: isWide
          ? EdgeInsets.all(48.0)
          : EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isWide ? 52.0 : 40.0,
                height: isWide ? 52.0 : 40.0,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.corporate_fare,
                  color: Colors.white,
                  size: isWide ? 28.0 : 18.0,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Sri HR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 28.0 : 24.0,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: isWide ? 40.0 : 24.0),
          Text(
            'Multi-Company HR Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 36.0 : 16.0,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
              height: 1.2,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Streamline attendance, leaves, payroll and more — all in one platform.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isWide ? 15.0 : 14.0,
              height: 1.6,
            ),
          ),
          SizedBox(height: isWide ? 40.0 : 20.0),
          ...[
            ('✓ Multi-tenant isolation'),
            ('✓ Role-based access control'),
            ('✓ Real-time attendance tracking'),
            ('✓ Complete HR workflow'),
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
