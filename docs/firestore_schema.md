# Firestore Schema — Ascend AI

## Collections

### `users/{userId}`
```json
{
  "id": "string",
  "identityGoal": "string",
  "deadline": "oneMonth | threeMonths | sixMonths | oneYear | twoYears | custom",
  "customDeadlineDays": "number?",
  "skillLevel": "beginner | intermediate | advanced | professional",
  "dailyHours": "thirtyMin | oneHour | twoHours | fourHours | custom",
  "customDailyHours": "number?",
  "motivation": "string",
  "displayName": "string?",
  "onboardingComplete": "boolean",
  "createdAt": "timestamp",
  "xp": "number",
  "level": "number",
  "currentStreak": "number",
  "longestStreak": "number",
  "aiPersonality": "supportiveCoach | strictMentor | friendlyBuddy | strategist"
}
```

### `users/{userId}/roadmaps/{roadmapId}`
```json
{
  "id": "string",
  "userId": "string",
  "longTermGoal": "GoalItem",
  "monthlyGoals": ["GoalItem"],
  "weeklyGoals": ["GoalItem"],
  "dailyTasks": ["GoalItem"],
  "todaysMission": "GoalItem?",
  "version": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### `users/{userId}/accountability/{recordId}`
```json
{
  "id": "string",
  "date": "timestamp",
  "status": "yes | partial | no",
  "skipReason": "tooBusy | lazy | didntKnow | health | other?",
  "note": "string?",
  "missionId": "string?"
}
```

### `users/{userId}/habits/{habitId}`
```json
{
  "id": "string",
  "name": "string",
  "icon": "string",
  "streak": "number",
  "completedDates": ["timestamp"],
  "isCustom": "boolean",
  "reminderTime": "string?"
}
```

### `users/{userId}/journal/{entryId}`
```json
{
  "id": "string",
  "date": "timestamp",
  "success": "string",
  "problems": "string",
  "mood": "number (1-5)",
  "energy": "number (1-5)",
  "aiSummary": "string?"
}
```

### `users/{userId}/focus_sessions/{sessionId}`
```json
{
  "id": "string",
  "startedAt": "timestamp",
  "endedAt": "timestamp?",
  "durationMinutes": "number",
  "completed": "boolean",
  "goalTitle": "string?"
}
```

### `users/{userId}/achievements/{achievementId}`
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "icon": "string",
  "unlockedAt": "timestamp?",
  "xpReward": "number"
}
```

### `users/{userId}/vision_board/{itemId}`
```json
{
  "id": "string",
  "title": "string",
  "imageUrl": "string",
  "category": "string?",
  "createdAt": "timestamp"
}
```

### `users/{userId}/chat_messages/{messageId}`
```json
{
  "id": "string",
  "content": "string",
  "isUser": "boolean",
  "timestamp": "timestamp"
}
```

## GoalItem Sub-document
```json
{
  "id": "string",
  "title": "string",
  "description": "string?",
  "period": "longTerm | monthly | weekly | daily | mission",
  "parentId": "string?",
  "isCompleted": "boolean",
  "completedAt": "timestamp?",
  "dueDate": "timestamp?",
  "estimatedHours": "number?",
  "order": "number"
}
```

## Indexes
- `users/{userId}/accountability` — `date` DESC
- `users/{userId}/journal` — `date` DESC
- `users/{userId}/focus_sessions` — `startedAt` DESC
