// ═══════════════════════════════════════════════════════════════
//  YOUR_FLUTTER_PROJECT/
//  ├── android/
//  ├── ios/
//  ├── lib/
//  ├── functions/          ← ഈ folder-ൽ വേണം
//  │   ├── index.js        ← ഈ file ഇവിടെ
//  │   └── package.json
//  └── pubspec.yaml
//
//  SETUP:
//  cd functions
//  npm install axios
//  firebase deploy --only functions
// ═══════════════════════════════════════════════════════════════

const functions = require('firebase-functions');
const admin     = require('firebase-admin');
const axios     = require('axios');
const crypto    = require('crypto');

admin.initializeApp();

// ═══════════════════════════════════════════════════════════════
//  PRODUCTION CREDENTIALS
//  PhonePe Dashboard → Integrations → API Keys
// ═══════════════════════════════════════════════════════════════
const MERCHANT_ID = 'SU2510131220392529332086'; // ← paste here
const SALT_KEY    = '2e662679-fdf7-42b3-a565-0f7c3ac1d1d6';    // ← paste here
const SALT_INDEX  = '1';                           // usually 1

const BASE_URL    = 'https://api.phonepe.com/apis'; // Production URL

// ─────────────────────────────────────────────────────────────
//  Helper: SHA256 Checksum
// ─────────────────────────────────────────────────────────────
function makeChecksum(input) {
  const hash = crypto.createHash('sha256').update(input).digest('hex');
  return `${hash}###${SALT_INDEX}`;
}

// ═══════════════════════════════════════════════════════════════
//  initiatePayment
//  Flutter → ഈ function → PhonePe API → payUrl return
// ═══════════════════════════════════════════════════════════════
exports.initiatePayment = functions.https.onCall(async (data, context) => {

  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { invoiceId, invoiceNo, amount, mobileNumber } = data;

  if (!invoiceId || amount == null) {
    throw new functions.https.HttpsError('invalid-argument', 'invoiceId and amount required');
  }

  const uid   = context.auth.uid;
  const paise = Math.round(Number(amount) * 100);

  if (paise <= 0) {
    throw new functions.https.HttpsError('invalid-argument', 'amount must be > 0');
  }

  const safeId = invoiceId.replace(/[^a-zA-Z0-9]/g, '').substring(0, 10);
  const txnId  = `TXN${safeId}${Date.now()}`;

  const payload = {
    merchantId:            MERCHANT_ID,
    merchantTransactionId: txnId,
    merchantUserId:        `USER_${uid}`,
    amount:                paise,
    redirectUrl:           'https://proconnect.app/payment/redirect',
    redirectMode:          'POST',
    mobileNumber:          (mobileNumber || '9999999999').toString().replace(/\D/g, ''),
    paymentInstrument:     { type: 'PAY_PAGE' },
  };

  const b64      = Buffer.from(JSON.stringify(payload)).toString('base64');
  const checksum = makeChecksum(`${b64}/pg/checkout/v2/pay${SALT_KEY}`);

  functions.logger.info('[PhonePe] initiatePayment', { txnId, paise, merchantId: MERCHANT_ID });

  let resp;
  try {
    resp = await axios.post(
      `${BASE_URL}/pg/checkout/v2/pay`,
      { request: b64 },
      {
        headers: {
          'Content-Type':  'application/json',
          'X-VERIFY':      checksum,
          'X-MERCHANT-ID': MERCHANT_ID,
          'accept':        'application/json',
        },
        timeout: 30000,
        validateStatus: () => true,
      }
    );
  } catch (netErr) {
    functions.logger.error('[PhonePe] Network error:', netErr.message);
    throw new functions.https.HttpsError('internal', `Network error: ${netErr.message}`);
  }

  const body = resp.data;
  functions.logger.info('[PhonePe] Response:', { status: resp.status, code: body?.code, success: body?.success });

  if (resp.status !== 200) {
    const msg = body?.message || `HTTP ${resp.status}`;
    throw new functions.https.HttpsError('internal', `PhonePe: ${msg}`);
  }

  if (body.success !== true) {
    return { success: false, message: body.message || body.code || 'Initiation failed' };
  }

  const payUrl = body?.data?.instrumentResponse?.redirectInfo?.url;
  if (!payUrl) {
    throw new functions.https.HttpsError('internal', 'PhonePe URL missing in response');
  }

  // Pending transaction save
  await admin.firestore().collection('payment_transactions').add({
    invoiceId,
    invoiceNo:     invoiceNo || '',
    merchantTxnId: txnId,
    amount:        Number(amount),
    clientId:      uid,
    status:        'PENDING',
    gateway:       'phonepe',
    createdAt:     admin.firestore.FieldValue.serverTimestamp(),
  });

  functions.logger.info('[PhonePe] Initiated OK', { txnId });
  return { success: true, payUrl, txnId };
});

// ═══════════════════════════════════════════════════════════════
//  verifyPayment
//  WebView complete → server-side verify → invoice paid mark
// ═══════════════════════════════════════════════════════════════
exports.verifyPayment = functions.https.onCall(async (data, context) => {

  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { txnId, invoiceId, invoiceNo, amount } = data;

  if (!txnId || !invoiceId) {
    throw new functions.https.HttpsError('invalid-argument', 'txnId and invoiceId required');
  }

  const path     = `/pg/v2/status/${MERCHANT_ID}/${txnId}`;
  const checksum = makeChecksum(`${path}${SALT_KEY}`);

  functions.logger.info('[PhonePe] verifyPayment', { txnId, invoiceId });

  let resp;
  try {
    resp = await axios.get(`${BASE_URL}${path}`, {
      headers: {
        'Content-Type':  'application/json',
        'X-VERIFY':      checksum,
        'X-MERCHANT-ID': MERCHANT_ID,
        'accept':        'application/json',
      },
      timeout: 15000,
      validateStatus: () => true,
    });
  } catch (netErr) {
    functions.logger.error('[PhonePe] verifyPayment network error:', netErr.message);
    return { success: false, message: `Network error: ${netErr.message}` };
  }

  const body    = resp.data;
  const success = body?.code === 'PAYMENT_SUCCESS';

  functions.logger.info('[PhonePe] Verify result:', { code: body?.code, success });

  if (success) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    try {
      // 1. Invoice → paid
      await admin.firestore().collection('invoices').doc(invoiceId).update({
        status:                'paid',
        paidAt:                now,
        paymentMode:           'PhonePe',
        merchantTransactionId: txnId,
      });

      // 2. Income record → accountant screen-ൽ കാണും
      await admin.firestore().collection('income').add({
        title:       `Invoice Payment – ${invoiceNo || invoiceId}`,
        amount:      Number(amount) || 0,
        category:    'Invoice Payment',
        paymentMode: 'PhonePe',
        reference:   txnId,
        invoiceId,
        note:        'Online payment via PhonePe',
        date:        now,
        createdAt:   now,
        isDeleted:   false,
      });

      // 3. Transaction → SUCCESS
      const snap = await admin.firestore()
        .collection('payment_transactions')
        .where('merchantTxnId', '==', txnId)
        .limit(1)
        .get();
      if (!snap.empty) {
        await snap.docs[0].ref.update({ status: 'SUCCESS', paidAt: now });
      }

      functions.logger.info('[PhonePe] Invoice marked paid', { invoiceId });
    } catch (fsErr) {
      functions.logger.error('[PhonePe] Firestore update failed:', fsErr.message);
    }
  }

  return { success, code: body?.code || '', message: body?.message || '' };
});