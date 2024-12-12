import 'package:google_auth/screens/home.dart';
import 'package:google_auth/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Get the current authenticated user
  getCurrentUser() async {
    return auth.currentUser;
  }

  // Sign in with Google
  signInWithGoogle(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // User cancelled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      UserCredential result = await auth.signInWithCredential(credential);

      User? userDetails = result.user;

      if (userDetails != null) {
        Map<String, dynamic> userInfoMap = {
          "email": userDetails.email,
          "name": userDetails.displayName,
          "imgUrl": userDetails.photoURL,
          "id": userDetails.uid,
        };

        await DatabaseMethods().addUser(userDetails.uid, userInfoMap).then((value) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Home()));
        });
      }
    } catch (e) {
      print("Error signing in with Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error signing in with Google")));
    }
  }

  // Sign in with Apple
  Future<User> signInWithApple({List<Scope> scopes = const []}) async {
    try {
      final result = await TheAppleSignIn.performRequests(
          [AppleIdRequest(requestedScopes: scopes)]);

      switch (result.status) {
        case AuthorizationStatus.authorized:
          final appleIdCredential = result.credential!;
          final oAuthCredential = OAuthProvider('apple.com');
          final credential = oAuthCredential.credential(
            idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          );

          final UserCredential userCredential = await auth.signInWithCredential(credential);
          final firebaseUser = userCredential.user!;

          if (scopes.contains(Scope.fullName)) {
            final fullName = appleIdCredential.fullName;
            if (fullName != null && fullName.givenName != null && fullName.familyName != null) {
              final displayName = '${fullName.givenName} ${fullName.familyName}';
              await firebaseUser.updateDisplayName(displayName);
            }
          }
          return firebaseUser;

        case AuthorizationStatus.error:
          throw PlatformException(
              code: 'ERROR_AUTHORIZATION_DENIED',
              message: result.error.toString());

        case AuthorizationStatus.cancelled:
          throw PlatformException(
              code: 'ERROR_ABORTED_BY_USER', message: 'Sign-in aborted by user');

        default:
          throw UnimplementedError();
      }
    } catch (e) {
      print("Error signing in with Apple: $e");
      throw PlatformException(code: 'ERROR_UNKNOWN', message: 'Unknown error during Apple Sign-in');
    }
  }

  // Log out
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('jwt');
  }
}
