import 'database_factory_initializer_stub.dart'
    if (dart.library.io) 'database_factory_initializer_io.dart' as impl;

Future<void> ensureDatabaseFactoryInitialized() =>
    impl.ensureDatabaseFactoryInitialized();
