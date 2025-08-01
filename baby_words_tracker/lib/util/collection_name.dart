class CollectionName {
  final String _name;
  final String _demoPrefix;

  CollectionName(this._name, {String demoPrefix = 'demo_'})
      : _demoPrefix = demoPrefix;

  String get name => _name;

  String get demoName => '$_demoPrefix$_name';

  String demoAwareCollectionName(bool useDemoCollection) {
    return useDemoCollection ? demoName : name;
  }

  @override
  String toString() {
    return 'CollectionName(name: $_name, demoPrefix: $_demoPrefix)';
  }
}
