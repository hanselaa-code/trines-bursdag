import '../models/question.dart';

final List<Question> dummyQuestions = [
  Question(
    id: '1',
    text: 'Hvor mange år er dette siden?',
    type: QuestionType.slider,
    imageUrl: 'assets/20170624_180346.jpg', 
    minSlider: 0,
    maxSlider: 20,
    correctNumber: 9, 
  ),
  Question(
    id: '2',
    text: 'Hva er Trines favorittfarge?',
    options: ['Rød', 'Grønn', 'Blå', 'Gul'],
    correctOptionIndex: 1,
  ),
  Question(
    id: '3',
    text: 'Hvilken by er Trine født i?',
    options: ['Oslo', 'Bergen', 'Trondheim', 'Stavanger'],
    correctOptionIndex: 0,
  ),
  Question(
    id: '4',
    text: 'Hvilken hobby bruker Trine mest tid på?',
    options: ['Strikking', 'Trening', 'Baking', 'Lesing'],
    correctOptionIndex: 1,
  ),
  Question(
    id: '5',
    text: 'Hva er Trines favorittmat?',
    options: ['Pizza', 'Taco', 'Sushi', 'Biff'],
    correctOptionIndex: 1,
  ),
  Question(
    id: '6',
    text: 'Gjett et tall! Hvor mye kostet Trines første bil?',
    type: QuestionType.slider,
    minSlider: 1000,
    maxSlider: 100000,
    correctNumber: 15000,
  ),
  Question(
    id: '7',
    text: 'Hvor mange søsken har Trine?',
    options: ['0', '1', '2', '3'],
    correctOptionIndex: 2,
  ),
  Question(
    id: '8',
    text: 'Hva heter hunden til Trine?',
    options: ['Fido', 'Bella', 'Luna', 'Max'],
    correctOptionIndex: 2,
  ),
  Question(
    id: '9',
    text: 'Hvilket TV-program bytter aldri Trine kanal når det går?',
    options: ['Nytt på nytt', 'Farmen', 'Maskorama', 'Mesternes Mester'],
    correctOptionIndex: 3,
  ),
  Question(
    id: '10',
    text: 'Hva var Trines første bil?',
    options: ['VW Golf', 'Toyota Corolla', 'Volvo 240', 'Nissan Leaf'],
    correctOptionIndex: 0,
  ),
];
