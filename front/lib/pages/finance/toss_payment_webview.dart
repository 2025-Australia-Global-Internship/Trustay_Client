import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:front/constants/colors.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/widgets/custom_header.dart';

/// 토스 결제 위젯 (테스트 키) 을 WebView 로 띄워 결제 흐름을 보여주는 페이지.
///
/// 실제 송금이 발생하지 않는 테스트 결제이지만, 토스의 결제창 UI 가 그대로 노출되어
/// 사용자에게 결제 흐름을 시뮬레이션해줄 수 있다.
///
/// 흐름:
///   1) 백엔드에서 토스 클라이언트키 조회 (`getTossClientConfig`).
///   2) inline HTML 페이지를 WebView 로 로드.
///   3) 사용자가 "Pay" 누르면 토스 SDK 가 결제창을 띄움.
///   4) 결제 성공 시 `successUrl` 로 리다이렉트.
///       └ NavigationDelegate 가 그 URL 을 가로채 `paymentKey/orderId/amount` 추출.
///       └ 백엔드 `confirmPayment` 호출 → `Navigator.pop(context, true)`.
///   5) 실패/취소 시 `failUrl` 로 리다이렉트 → `Navigator.pop(context, false)`.
class TossPaymentWebView extends StatefulWidget {
  /// 결제할 금액 (백엔드 Payment.amount 와 동일해야 한다).
  final int amount;

  /// 백엔드에서 발급된 결제 주문 ID. confirm 호출 시 키로 쓰인다.
  final String orderId;

  /// 결제창에 표시될 주문명 (예: "Shared Meal — Olivia").
  final String orderName;

  /// 결제자의 식별자 (토스 customerKey 로 사용). 보통 본인의 memberId.
  final String customerKey;

  /// 결제자의 이름 (선택).
  final String? customerName;

  const TossPaymentWebView({
    super.key,
    required this.amount,
    required this.orderId,
    required this.orderName,
    required this.customerKey,
    this.customerName,
  });

  @override
  State<TossPaymentWebView> createState() => _TossPaymentWebViewState();
}

class _TossPaymentWebViewState extends State<TossPaymentWebView> {
  static const String _successUrl = 'https://trustay.app/toss/success';
  static const String _failUrl = 'https://trustay.app/toss/fail';

  late final WebViewController _controller;
  bool _isBootstrapping = true;
  bool _isConfirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final config = await PaymentService.getTossClientConfig();
      final html = _buildHtml(config.clientKey);

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest req) {
              final url = req.url;
              if (url.startsWith(_successUrl)) {
                _handleSuccess(url);
                return NavigationDecision.prevent;
              }
              if (url.startsWith(_failUrl)) {
                _handleFail(url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(html, baseUrl: 'https://trustay.app/');

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isBootstrapping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to open Toss payment: $e';
        _isBootstrapping = false;
      });
    }
  }

  /// successUrl 리다이렉트에서 paymentKey/orderId/amount 추출하여 백엔드 confirm 호출.
  Future<void> _handleSuccess(String url) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    try {
      final uri = Uri.parse(url);
      final paymentKey = uri.queryParameters['paymentKey'] ?? '';
      final orderId = uri.queryParameters['orderId'] ?? widget.orderId;
      final amount = int.tryParse(uri.queryParameters['amount'] ?? '') ??
          widget.amount;

      await PaymentService.confirmPayment(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _error = 'Payment confirm failed: $e';
      });
    }
  }

  void _handleFail(String url) {
    if (!mounted) return;
    final uri = Uri.parse(url);
    final message = uri.queryParameters['message'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment cancelled${message != null ? ': $message' : ''}.')),
    );
    Navigator.pop(context, false);
  }

  String _buildHtml(String clientKey) {
    // 토스페이먼츠 JavaScript SDK v2 (Standard) 기반 인라인 HTML.
    //   https://docs.tosspayments.com/sdk/v2/js
    // 호출 흐름: TossPayments(clientKey).widgets({customerKey})
    //   → setAmount → renderPaymentMethods → renderAgreement → requestPayment
    // 안전을 위해 JS 문자열 리터럴은 jsonEncode 로 이스케이프한다.
    String j(Object v) => jsonEncode(v);

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Toss Payment</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      margin: 0;
      padding: 16px;
      background: #fafafa;
      color: #1A1A1A;
    }
    .summary {
      background: #fff;
      border-radius: 14px;
      padding: 16px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.04);
      margin-bottom: 16px;
    }
    .summary .name { font-size: 13px; color: #888; font-weight: 600; }
    .summary .amount { font-size: 28px; font-weight: 800; color: #454B27; margin-top: 6px; }
    .pay-btn {
      width: 100%;
      padding: 16px;
      background: #FFF27B;
      color: #1A1A1A;
      font-size: 15px;
      font-weight: 800;
      border: none;
      border-radius: 28px;
      margin-top: 16px;
    }
    .pay-btn:disabled { opacity: 0.6; }
    #payment-method, #agreement {
      background: #fff;
      border-radius: 14px;
      overflow: hidden;
      margin-bottom: 12px;
    }
    .err { color:#c0392b; font-size: 13px; margin-top: 8px; white-space: pre-wrap; }
  </style>
</head>
<body>
  <div class="summary">
    <div class="name">${widget.orderName.replaceAll('<', '&lt;')}</div>
    <div class="amount">₩${widget.amount}</div>
  </div>
  <div id="payment-method"></div>
  <div id="agreement"></div>
  <button id="payment-button" class="pay-btn" disabled>Pay</button>
  <div id="err" class="err"></div>

  <script src="https://js.tosspayments.com/v2/standard"></script>
  <script>
    (async () => {
      const clientKey = ${j(clientKey)};
      const customerKey = ${j(widget.customerKey)};
      const orderId = ${j(widget.orderId)};
      const orderName = ${j(widget.orderName)};
      const amount = ${widget.amount};
      const successUrl = ${j(_successUrl)};
      const failUrl = ${j(_failUrl)};
      const customerName = ${j(widget.customerName ?? '')};

      const btn = document.getElementById('payment-button');
      const errBox = document.getElementById('err');
      try {
        const tossPayments = TossPayments(clientKey);
        const widgets = tossPayments.widgets({ customerKey: customerKey });
        await widgets.setAmount({ currency: 'KRW', value: amount });
        await widgets.renderPaymentMethods({
          selector: '#payment-method',
          variantKey: 'DEFAULT',
        });
        const agreementWidget = await widgets.renderAgreement({
          selector: '#agreement',
          variantKey: 'AGREEMENT',
        });
        // 약관 체크 후에만 결제 버튼 활성화 (필수 약관에 동의해야 결제 가능).
        agreementWidget.on('agreementStatusChange', (status) => {
          btn.disabled = !status.agreedRequiredTerms;
        });
        btn.addEventListener('click', () => {
          widgets.requestPayment({
            orderId: orderId,
            orderName: orderName,
            customerName: customerName || undefined,
            successUrl: successUrl,
            failUrl: failUrl,
          }).catch((err) => {
            errBox.innerText = (err && err.message) || 'Payment failed.';
          });
        });
      } catch (err) {
        errBox.innerText = (err && err.message) || 'Toss SDK init failed.';
      }
    })();
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const CustomHeader(
            showBack: true,
            toolbarHeight: 56,
            center: Text(
              'Toss Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
          ),
          if (_isBootstrapping)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: green)),
            )
          else if (_error != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: dark, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isConfirming)
                    Container(
                      color: Colors.black.withOpacity(0.25),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(color: green),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
