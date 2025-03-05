import React, { useState } from 'react';
import { Heart, MessageCircle, Calendar, HelpCircle, Archive, Star, ArrowRight, ArrowLeft } from 'lucide-react';

// Sample initial data with predefined quizzes
const initialQuizzes = [
  {
    id: 1,
    title: "How Well Do You Know Your Partner?",
    questions: [
      {
        question: "What's their dream vacation?",
        options: [
          "Tropical Beach",
          "Mountain Adventure",
          "City Exploration",
          "Relaxing Cruise"
        ]
      },
      {
        question: "What's their biggest fear?",
        options: [
          "Heights",
          "Public Speaking",
          "Failure",
          "Loneliness"
        ]
      },
      {
        question: "What's their favorite memory with you?",
        options: [
          "First Date",
          "Spontaneous Road Trip",
          "Cozy Night In",
          "Milestone Celebration"
        ]
      }
    ]
  },
  {
    id: 2,
    title: "Love Language Quiz",
    questions: [
      {
        question: "How do you prefer to receive affection?",
        options: [
          "Words of Affirmation",
          "Physical Touch",
          "Acts of Service",
          "Quality Time"
        ]
      },
      {
        question: "What makes you feel most loved?",
        options: [
          "Surprises",
          "Deep Conversations",
          "Helping with Chores",
          "Gifts"
        ]
      },
      {
        question: "Your partner's love language?",
        options: [
          "Receiving Gifts",
          "Physical Affection",
          "Words of Support",
          "Shared Experiences"
        ]
      }
    ]
  }
];

const dateIdeas = [
  "🍽️ Romantic Dinner",
  "🎬 Movie Night",
  "🚶 Scenic Walk",
  "🎳 Bowling",
  "🍦 Ice Cream Date",
  "🎨 Art Gallery Visit",
  "🏞️ Picnic in the Park",
  "🍷 Wine Tasting",
  "🎮 Game Night",
  "🧘 Couples Yoga"
];

const CouplesApp = () => {
  const [activeTab, setActiveTab] = useState('hub');
  const [dailyQuestion, setDailyQuestion] = useState("What moment today made you smile?");
  const [dateIdeasIndex, setDateIdeasIndex] = useState(0);
  const [partnerLinked, setPartnerLinked] = useState(false);
  const [quizResponses, setQuizResponses] = useState({});
  const [dailyResponses, setDailyResponses] = useState([]);
  const [dateIdeasHistory, setDateIdeasHistory] = useState([]);
  
  // New quiz state management
  const [currentQuiz, setCurrentQuiz] = useState(null);
  const [currentQuizIndex, setCurrentQuizIndex] = useState(0);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);

  const handleQuizResponse = (response) => {
    // Store the response for the current quiz and question
    setQuizResponses(prev => ({
      ...prev,
      [currentQuiz.id]: {
        ...(prev[currentQuiz.id] || {}),
        [currentQuestionIndex]: response
      }
    }));

    // Move to next question or next quiz
    if (currentQuestionIndex < currentQuiz.questions.length - 1) {
      setCurrentQuestionIndex(prev => prev + 1);
    } else if (currentQuizIndex < initialQuizzes.length - 1) {
      // Move to next quiz
      setCurrentQuizIndex(prev => prev + 1);
      setCurrentQuestionIndex(0);
      setCurrentQuiz(initialQuizzes[currentQuizIndex + 1]);
    } else {
      // All quizzes completed
      setCurrentQuiz(null);
      setCurrentQuizIndex(0);
      setCurrentQuestionIndex(0);
    }
  };

  const startQuiz = (quiz) => {
    setCurrentQuiz(quiz);
    setCurrentQuizIndex(initialQuizzes.indexOf(quiz));
    setCurrentQuestionIndex(0);
  };

  const handleDateIdea = (response) => {
    const currentIdea = dateIdeas[dateIdeasIndex];
    setDateIdeasHistory(prev => [
      ...prev, 
      { idea: currentIdea, response, date: new Date().toLocaleDateString() }
    ]);

    switch(response) {
      case 'yes':
        alert("Great! Let's plan this date! 💕");
        break;
      case 'maybe':
        alert("Discuss and see if you both like it! 🤔");
        break;
      case 'no':
        setDateIdeasIndex((prev) => (prev + 1) % dateIdeas.length);
        break;
    }
  };

  const handleDailyQuestionSubmit = (response) => {
    setDailyResponses(prev => [
      ...prev, 
      { question: dailyQuestion, response, date: new Date().toLocaleDateString() }
    ]);
  };

  const renderContent = () => {
    switch(activeTab) {
      case 'hub':
        return (
          <div className="p-4">
            <h2 className="text-2xl font-bold mb-4">📊 Relationship Hub</h2>
            
            <div className="bg-gray-800 rounded p-4 mb-4">
              <h3 className="font-bold mb-2">🤔 Quiz History</h3>
              {Object.entries(quizResponses).map(([quizId, responses]) => {
                const quiz = initialQuizzes.find(q => q.id === parseInt(quizId));
                return (
                  <div key={quizId} className="mb-2">
                    <p className="text-pink-400">{quiz?.title}</p>
                    {Object.entries(responses).map(([questionIndex, response]) => {
                      const question = quiz.questions[parseInt(questionIndex)];
                      return (
                        <div key={questionIndex} className="text-sm">
                          {question.question}: {response}
                        </div>
                      );
                    })}
                  </div>
                );
              })}
            </div>

            <div className="bg-gray-800 rounded p-4 mb-4">
              <h3 className="font-bold mb-2">❓ Daily Questions</h3>
              {dailyResponses.map((entry, index) => (
                <div key={index} className="mb-2">
                  <p className="text-pink-400">{entry.date}</p>
                  <p>{entry.question}</p>
                  <p>{entry.response}</p>
                </div>
              ))}
            </div>

            <div className="bg-gray-800 rounded p-4">
              <h3 className="font-bold mb-2">🌟 Date Ideas History</h3>
              {dateIdeasHistory.map((entry, index) => (
                <div key={index} className="mb-2">
                  <p className="text-pink-400">{entry.date}</p>
                  <p>{entry.idea} - {entry.response}</p>
                </div>
              ))}
            </div>
          </div>
        );
      case 'quizzes':
        return (
          <div className="p-4">
            {!currentQuiz ? (
              <>
                <h2 className="text-xl font-bold mb-4">🤔 Relationship Quizzes</h2>
                {initialQuizzes.map(quiz => (
                  <div 
                    key={quiz.id} 
                    className="bg-gray-800 rounded p-4 mb-4 cursor-pointer hover:bg-gray-700"
                    onClick={() => startQuiz(quiz)}
                  >
                    <h3 className="font-bold mb-2">{quiz.title}</h3>
                    <p className="text-sm text-gray-400">Tap to start quiz</p>
                  </div>
                ))}
              </>
            ) : (
              <div className="bg-gray-800 rounded p-4">
                <h3 className="font-bold mb-4">{currentQuiz.title}</h3>
                <p className="mb-4">Question {currentQuestionIndex + 1} of {currentQuiz.questions.length}</p>
                
                <div className="mb-4">
                  <p className="text-lg mb-4">
                    {currentQuiz.questions[currentQuestionIndex].question}
                  </p>
                  
                  <div className="grid grid-cols-2 gap-2">
                    {currentQuiz.questions[currentQuestionIndex].options.map((option, optionIndex) => (
                      <button
                        key={optionIndex}
                        onClick={() => handleQuizResponse(option)}
                        className={`p-2 rounded text-sm ${
                          quizResponses[currentQuiz.id]?.[currentQuestionIndex] === option 
                            ? 'bg-pink-600 text-white' 
                            : 'bg-gray-700 text-gray-300'
                        }`}
                      >
                        {option}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        );
      case 'daily-question':
        return (
          <div className="p-4">
            <h2 className="text-xl font-bold mb-4">❓ Daily Connection Question</h2>
            <p className="text-lg mb-4">{dailyQuestion}</p>
            <textarea 
              placeholder="Share your thoughts..." 
              className="w-full p-2 bg-gray-800 text-white rounded h-32 mb-4"
              onChange={(e) => handleDailyQuestionSubmit(e.target.value)}
            />
            <button 
              className="bg-pink-600 text-white p-2 rounded"
              onClick={() => handleDailyQuestionSubmit}
            >
              Share with Partner 💖
            </button>
          </div>
        );
      case 'date-ideas':
        return (
          <div className="p-4 text-center">
            <h2 className="text-xl font-bold mb-4">🌟 Date Idea Picker</h2>
            <div className="text-6xl mb-4">{dateIdeas[dateIdeasIndex]}</div>
            <div className="flex justify-center space-x-4">
              <button 
                onClick={() => handleDateIdea('yes')} 
                className="bg-green-600 p-2 rounded"
              >
                Yes 👍
              </button>
              <button 
                onClick={() => handleDateIdea('maybe')} 
                className="bg-yellow-600 p-2 rounded"
              >
                Maybe 🤔
              </button>
              <button 
                onClick={() => handleDateIdea('no')} 
                className="bg-red-600 p-2 rounded"
              >
                No 👎
              </button>
            </div>
          </div>
        );
      case 'linker':
        return (
          <div className="p-4 text-center">
            {!partnerLinked ? (
              <>
                <h2 className="text-xl font-bold mb-4">🔗 Link Your Partner</h2>
                <input 
                  type="text" 
                  placeholder="Enter partner's invite code" 
                  className="w-full p-2 mb-4 bg-gray-800 text-white rounded"
                />
                <button 
                  className="bg-pink-600 text-white p-2 rounded"
                  onClick={() => setPartnerLinked(true)}
                >
                  Link Partner 💑
                </button>
              </>
            ) : (
              <div>
                <h2 className="text-xl font-bold mb-4">💕 Connected with Sarah</h2>
                <p>You're now linked! Share moments, take quizzes, and grow together.</p>
              </div>
            )}
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="bg-gray-900 text-white min-h-screen">
      <div className="container mx-auto max-w-md">
        {/* Content Area */}
        <div className="pt-16 pb-20">
          {renderContent()}
        </div>

        {/* Bottom Navigation */}
        <div className="fixed bottom-0 left-0 right-0 bg-gray-800 p-4">
          <div className="flex justify-around">
            <button 
              onClick={() => setActiveTab('hub')}
              className={`flex flex-col items-center ${activeTab === 'hub' ? 'text-pink-500' : 'text-gray-400'}`}
            >
              <Archive size={24} />
              <span className="text-xs mt-1">Hub</span>
            </button>
            <button 
              onClick={() => {
                setActiveTab('quizzes');
                setCurrentQuiz(null);
              }}
              className={`flex flex-col items-center ${activeTab === 'quizzes' ? 'text-pink-500' : 'text-gray-400'}`}
            >
              <HelpCircle size={24} />
              <span className="text-xs mt-1">Quizzes</span>
            </button>
            <button 
              onClick={() => setActiveTab('daily-question')}
              className={`flex flex-col items-center ${activeTab === 'daily-question' ? 'text-pink-500' : 'text-gray-400'}`}
            >
              <MessageCircle size={24} />
              <span className="text-xs mt-1">Daily Q</span>
            </button>
            <button 
              onClick={() => setActiveTab('date-ideas')}
              className={`flex flex-col items-center ${activeTab === 'date-ideas' ? 'text-pink-500' : 'text-gray-400'}`}
            >
              <Calendar size={24} />
              <span className="text-xs mt-1">Date Ideas</span>
            </button>
            <button 
              onClick={() => setActiveTab('linker')}
              className={`flex flex-col items-center ${activeTab === 'linker' ? 'text-pink-500' : 'text-gray-400'}`}
            >
              <Heart size={24} />
              <span className="text-xs mt-1">Linker</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CouplesApp;
