import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/LoginScreen.dart';
import 'screens/RegisterScreen.dart';
import 'screens/DashboardScreen.dart';
import 'screens/ListaProductosScreen.dart';
import 'screens/AddProductScreen.dart';
import 'screens/ProductDetailScreen.dart';
import 'screens/new_detection_screen.dart';
import 'screens/product_datasets_screen.dart';
import 'screens/dataset_images_screen.dart';
import 'screens/product_model_screen.dart';
import 'screens/product_report_screen.dart';
import 'screens/TrainingHistoryScreen.dart';
import 'screens/helper_screen.dart';
import 'screens/about_screen.dart';
import 'screens/SettingsScreen.dart';
import 'screens/models_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/category_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caffe',
      initialRoute: '/login',
      // Definición de rutas
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(), // ¡Esta es la que falta!
        '/dashboard': (context) => DashboardScreen(),
        '/products': (context) => ProductsScreen(),
        '/products/add': (context) => AddProductPage(),
        '/products/detail': (context) => ProductDetailScreen(),
        '/detections/new': (context) => NewDetectionScreen(),
        '/products/datasets': (context) => ProductDatasetsScreen(),
        '/datasets/images': (context) => DatasetImagesScreen(),
        '/products/models': (context) => ProductModelsScreen(),
        '/products/models/history': (context) => TrainingHistoryScreen(),
        '/products/reports': (context) => ProductSearchScreen(),
        '/helper': (context) => HelperScreen(),
        '/about': (context) => AboutScreen(),
        '/settings': (context) => SettingsScreen(),
        '/models': (context) => ModelsScreen(),
        '/detections':
            (context) => RealTimeDetectionScreen(
              wsUrl:
                  "ws://192.168.0.13:8765", // tu servidor WebSocket// ID del modelo que quieres usar
            ),
        '/category': (context) => CategoryScreen(),
      },
    );
  }
}
