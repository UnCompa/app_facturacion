import 'package:amplify_flutter/amplify_flutter.dart';

class UserService {
  static Future<String> getRolUser() async {
    final userAttributes = await Amplify.Auth.fetchUserAttributes();
      final roleAttr = userAttributes.firstWhere(
        (attr)=> attr.userAttributeKey.key == 'custom:role',
        orElse: ()=> const AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom('role'),
          value: 'unknown',
        ),
      );

      final role = roleAttr.value.toLowerCase();
      return role;
  } 
}
