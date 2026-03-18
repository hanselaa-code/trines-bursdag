import 'package:firebase_core/firebase_core.dart';

// Kopier denne filen til firebase_config.dart og fyll inn dine verdier fra Firebase Console.
// firebase_config.dart er lagt til i .gitignore og skal IKKE committes.
const firebaseOptions = FirebaseOptions(
  apiKey: "DIN_API_NØKKEL_HER",
  authDomain: "ditt-prosjekt.firebaseapp.com",
  projectId: "ditt-prosjekt",
  storageBucket: "ditt-prosjekt.firebasestorage.app",
  messagingSenderId: "DITT_SENDER_ID",
  appId: "DIN_APP_ID",
  measurementId: "DIN_MEASUREMENT_ID",
);
