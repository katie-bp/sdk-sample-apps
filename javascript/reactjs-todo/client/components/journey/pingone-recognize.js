/*
 * forgerock-sample-web-react
 *
 * pingone-recognize.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import '@keyless/sdk-web-components';
import React, { useEffect, useState, useRef } from 'react';
import { DEBUGGER } from '../../constants';
import Loading from '../utilities/loading';

/**
 * @function PingOneRecognize - React component for handling PingOneRecognizeCallback
 * @param {FRStep} step - The current step in the authentication journey
 * @param {function} setSubmissionStep - Method to set the submission step
 * @returns {Object} - A React component
 */
export default function PingOneRecognize({ step, setSubmissionStep }) {
  const callback = step.callbacks.find((cb) => cb?.payload?.type === 'PingOneRecognizeCallback');
  const operationType = callback.payload.output.find((o) => o.name === 'operationType')?.value;

  if (operationType === 'ENROLL') {
    return <KeylessEnroll step={step} setSubmissionStep={setSubmissionStep} callback={callback} />;
  } else {
    return <KeylessAuth step={step} setSubmissionStep={setSubmissionStep} callback={callback} />;
  }
}

export function KeylessEnroll({ step, setSubmissionStep, callback }) {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(false);
  }, []);

  const onError = (event) => {
    if (DEBUGGER) debugger;
    callback.payload.input.find((i) => i.name === 'IDToken1clientError').value = event.message;
    callback.payload.input.find((i) => i.name === 'IDToken1clientErrorCode').value = event.code;
  };

  const onFinished = (event) => {
    if (DEBUGGER) debugger;
    callback.payload.input.find((i) => i.name === 'IDToken1signedJwt').value = event.transactionJwt;
    callback.payload.input.find((i) => i.name === 'IDToken1clientState').value = event.clientState;
    setSubmissionStep(step);
  };

  const customerName = callback.payload.output.find((o) => o.name === 'customerName')?.value;
  const imageEncryptionKeyId = callback.payload.output.find(
    (o) => o.name === 'imageEncryptionKeyId',
  )?.value;
  const imageEncryptionPublicKey = pemToRawBase64(callback.payload.output.find(
    (o) => o.name === 'imageEncryptionPublicKey',
  )?.value);
  const transactionData =
    callback.payload.output.find((o) => o.name === 'transactionData')?.value || 'test';
  const username = callback.payload.output.find((o) => o.name === 'username')?.value;
  const websocketURL = callback.payload.output.find((o) => o.name === 'websocketURL')?.value;

  if (DEBUGGER) debugger;
  return (
    <>
      {loading && <Loading message="Enrolling..." />}
      <kl-enroll
        customer={customerName}
        enable-camera-instructions
        key-id={imageEncryptionKeyId}
        lang="en"
        onerror={onError}
        onfinished={onFinished}
        public-key={imageEncryptionPublicKey}
        size="375"
        theme="light"
        transaction-data={transactionData}
        username={username}
        ws-url={websocketURL}
      />
    </>
  );
}

export function KeylessAuth({ step, setSubmissionStep, callback }) {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(false);
  }, []);

  const onError = (event) => {
    if (DEBUGGER) debugger;
    callback.payload.input.find((i) => i.name === 'IDToken1clientError').value = event.message;
    callback.payload.input.find((i) => i.name === 'IDToken1clientErrorCode').value = event.code;
  };

  const onFinished = (event) => {
    if (DEBUGGER) debugger;
    callback.payload.input.find((i) => i.name === 'IDToken1signedJwt').value = event.transactionJwt;
    callback.payload.input.find((i) => i.name === 'IDToken1clientState').value = event.clientState;
    callback.payload.input.find((i) => i.name === 'IDToken1recognizeId').value = event.keylessId;
    setSubmissionStep(step);
  };

  const customerName = callback.payload.output.find((o) => o.name === 'customerName')?.value;
  const imageEncryptionKeyId = callback.payload.output.find(
    (o) => o.name === 'imageEncryptionKeyId',
  )?.value;
  const imageEncryptionPublicKey = pemToRawBase64(callback.payload.output.find(
    (o) => o.name === 'imageEncryptionPublicKey',
  )?.value);
  const transactionData =
    callback.payload.output.find((o) => o.name === 'transactionData')?.value || 'test';
  const username = callback.payload.output.find((o) => o.name === 'username')?.value;
  const websocketURL = callback.payload.output.find((o) => o.name === 'websocketURL')?.value;

  return (
    <>
      {loading && <Loading message="Authenticating..." />}
      <kl-auth
        customer={customerName}
        enable-camera-instructions
        key-id={imageEncryptionKeyId}
        lang="en"
        onerror={onError}
        onfinished={onFinished}
        public-key={imageEncryptionPublicKey}
        size="375"
        theme="light"
        transaction-data={transactionData}
        username={username}
        ws-url={websocketURL}
      />
    </>
  );
}

function pemToRawBase64(pem) {
  if (!pem) return '';
  return pem
    .replace(/-----BEGIN PUBLIC KEY-----/, '')
    .replace(/-----END PUBLIC KEY-----/, '')
    .replace(/[\n\r\s]/g, '');
}
