/// The auth feature's public widgets (ARCH §5.2 rule 7). Other features
/// import this file, never auth's presentation/ files directly.
library;

export 'presentation/fresh_sign_in.dart' show askText, withFreshSignIn;
export 'presentation/verify_email_banner.dart'
    show VerifyEmailNotice, recheckEmailVerified;
