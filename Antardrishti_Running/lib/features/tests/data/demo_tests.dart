class DemoTest {
  final String name;
  final String description;

  const DemoTest({required this.name, required this.description});
}

const demoTests = [
  DemoTest(
    name: 'Vertical Jump',
    description: 'Record your max vertical jump',
  ),
  DemoTest(
    name: '20m Sprint',
    description: 'Short sprint for speed assessment',
  ),
  DemoTest(
    name: 'Sit-ups in 30s',
    description: 'Core endurance test',
  ),
];
