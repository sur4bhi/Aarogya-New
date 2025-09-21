enum FirstAidTopic {
  snakeBite('Snake bite'),
  bleeding('Severe bleeding'),
  chestPain('Chest pain'),
  fainting('Fainting');

  final String displayTitle;
  const FirstAidTopic(this.displayTitle);
}

class FirstAidService {
  static const topics = [
    FirstAidTopic.snakeBite,
    FirstAidTopic.bleeding,
    FirstAidTopic.chestPain,
    FirstAidTopic.fainting,
  ];

  static List<String> getGuide(FirstAidTopic topic) {
    switch (topic) {
      case FirstAidTopic.snakeBite:
        return [
          'Keep the person calm and still; immobilize the bitten limb below heart level.',
          'Remove tight clothing or jewelry near the bite area.',
          'Do NOT cut, suck, or apply ice to the wound.',
          'Prepare SOS and get to the nearest medical facility immediately.'
        ];
      case FirstAidTopic.bleeding:
        return [
          'Apply direct pressure with a clean cloth to stop bleeding.',
          'Elevate the injured area if possible.',
          'Do not remove embedded objects; apply pressure around them.',
          'Seek urgent medical help if bleeding is severe or does not stop.'
        ];
      case FirstAidTopic.chestPain:
        return [
          'Have the person sit and rest; loosen tight clothing.',
          'If available, chew an aspirin (unless allergic) while seeking help.',
          'Prepare SOS and call emergency services if pain is severe or lasts more than a few minutes.'
        ];
      case FirstAidTopic.fainting:
        return [
          'Lay the person on their back and elevate legs about 12 inches.',
          'Loosen tight clothing. Check breathing.',
          'If not breathing, begin CPR and call emergency services.',
        ];
    }
  }
}
