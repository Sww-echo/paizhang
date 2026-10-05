import 'dart:io';

bool isTransportError(Object error) =>
    error is SocketException || error is HttpException;
