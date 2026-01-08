import 'package:google_sign_in/google_sign_in.dart' as gsi;

class GoogleSigninService {
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn();

  Future<gsi.GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      // Logic for handling errors could go here
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
