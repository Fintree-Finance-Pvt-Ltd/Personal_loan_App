enum AppEnvironment { development, uat, production }

class Environment {
  final AppEnvironment env;
  final String apiBaseUrl;
  final String digitapEnv;
  final String paymentReturnScheme;
  final String esignReturnScheme;
  final String mandateReturnScheme;

  const Environment._({
    required this.env,
    required this.apiBaseUrl,
    required this.digitapEnv,
    required this.paymentReturnScheme,
    required this.esignReturnScheme,
    required this.mandateReturnScheme,
  });

  factory Environment.fromDartDefine() {
    const envString = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://pl-fintree-uat.fintreelms.com/api',
    );
    const digitapEnv = String.fromEnvironment('DIGITAP_ENV', defaultValue: 'sandbox');
    const paymentReturnScheme = String.fromEnvironment('PAYMENT_RETURN_SCHEME', defaultValue: 'pldirect://payment-return');
    const esignReturnScheme = String.fromEnvironment('ESIGN_RETURN_SCHEME', defaultValue: 'pldirect://esign-return');
    const mandateReturnScheme = String.fromEnvironment('MANDATE_RETURN_SCHEME', defaultValue: 'pldirect://mandate-return');

    AppEnvironment parsedEnv = AppEnvironment.development;
    if (envString == 'uat') {
      parsedEnv = AppEnvironment.uat;
    } else if (envString == 'production') {
      parsedEnv = AppEnvironment.production;
    }

    return Environment._(
      env: parsedEnv,
      apiBaseUrl: baseUrl,
      digitapEnv: digitapEnv,
      paymentReturnScheme: paymentReturnScheme,
      esignReturnScheme: esignReturnScheme,
      mandateReturnScheme: mandateReturnScheme,
    );
  }

  bool get isDevelopment => env == AppEnvironment.development;
  bool get isUat => env == AppEnvironment.uat;
  bool get isProduction => env == AppEnvironment.production;
}

late final Environment currentEnvironment;
