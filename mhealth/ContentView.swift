//
//  ContentView.swift
//  mhealth
//
//  Created by Isa Gonzalez on 3/11/25.
//

import SwiftUI
import Charts

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let muscleGroups: [String]
    var balanceData: [Double] = [] // Store bilateral balance data
}

struct ExerciseListView: View {
    let exercises = [
        Exercise(name: "Barbell Bench Press", 
                description: "A compound exercise targeting chest, shoulders, and triceps.",
                muscleGroups: ["Chest", "Shoulders", "Triceps"]),
        Exercise(name: "Dumbbell Shoulder Press",
                description: "An overhead press targeting shoulder development.",
                muscleGroups: ["Shoulders", "Triceps"]),
        Exercise(name: "Dumbbell Lateral Raises",
                description: "An isolation exercise for shoulder width.",
                muscleGroups: ["Shoulders"]),
        Exercise(name: "Bicep Curls",
                description: "An isolation exercise for bicep development.",
                muscleGroups: ["Biceps"]),
        Exercise(name: "Tricep Extensions",
                description: "An isolation exercise targeting tricep development.",
                muscleGroups: ["Triceps"])
    ]
    
    var body: some View {
        NavigationView {
            List(exercises) { exercise in
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.headline)
                        Text(exercise.muscleGroups.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("BEAM")
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var isWorkoutActive = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(exercise.name)
                .font(.title)
                .bold()
            
            Text(exercise.description)
                .multilineTextAlignment(.center)
                .padding()
            
            if isWorkoutActive {
                WorkoutView(exercise: exercise)
            } else {
                Button(action: {
                    isWorkoutActive = true
                }) {
                    Text("Start Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct WorkoutView: View {
    let exercise: Exercise
    @State private var leftSideBalance: Double = 0.0
    @State private var rightSideBalance: Double = 0.0
    @StateObject private var dataManager = WorkoutDataManager()
    
    // Simulated sensor data update timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Live Feedback")
                .font(.title2)
            
            HStack {
                VStack {
                    Text("Left Side")
                    Text("\(Int(leftSideBalance))%")
                        .font(.title)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                VStack {
                    Text("Right Side")
                    Text("\(Int(rightSideBalance))%")
                        .font(.title)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            }
            
            Text(feedbackMessage)
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(feedbackColor)
            
            // Live balance chart
            Chart {
                BarMark(
                    x: .value("Side", "Left"),
                    y: .value("Balance", leftSideBalance)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Side", "Right"),
                    y: .value("Balance", rightSideBalance)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 200)
            .padding()
        }
        .onReceive(timer) { _ in
            simulateSensorData()
        }
    }
    
    private var feedbackMessage: String {
        let difference = abs(leftSideBalance - rightSideBalance)
        if difference < 10 {
            return "Great balance! Keep it up!"
        } else if difference < 20 {
            return "Slight imbalance detected. Try to maintain even force."
        } else {
            return "Significant imbalance detected. Please adjust your form."
        }
    }
    
    private var feedbackColor: Color {
        let difference = abs(leftSideBalance - rightSideBalance)
        if difference < 10 {
            return .green
        } else if difference < 20 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func simulateSensorData() {
        // Simulate sensor data (replace with actual sensor implementation)
        leftSideBalance = Double.random(in: 40...60)
        rightSideBalance = Double.random(in: 40...60)
        
        // Store the data point
        dataManager.balanceData.append(BalanceDataPoint(
            date: Date(),
            leftSide: leftSideBalance,
            rightSide: rightSideBalance,
            exercise: exercise.name
        ))
    }
}

struct BalanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let leftSide: Double
    let rightSide: Double
    let exercise: String
}

class WorkoutDataManager: ObservableObject {
    @Published var balanceData: [BalanceDataPoint] = []
    
    init() {
        // Sample data for demonstration
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                balanceData.append(BalanceDataPoint(
                    date: date,
                    leftSide: Double.random(in: 40...60),
                    rightSide: Double.random(in: 40...60),
                    exercise: "Barbell Bench Press"
                ))
            }
        }
    }
}

struct StatsView: View {
    @StateObject private var dataManager = WorkoutDataManager()
    @State private var selectedTimeRange = 1 // 0: week, 1: month, 2: year
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        Text("Week").tag(0)
                        Text("Month").tag(1)
                        Text("Year").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    VStack(alignment: .leading) {
                        Text("Overall Balance Score")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(dataManager.balanceData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Left Side", point.leftSide),
                                series: .value("Side", "Left")
                            )
                            .foregroundStyle(.blue)
                            
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Right Side", point.rightSide),
                                series: .value("Side", "Right")
                            )
                            .foregroundStyle(.green)
                        }
                        .frame(height: 200)
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    ExerciseStatsGrid(data: dataManager.balanceData)
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct ExerciseStatsGrid: View {
    let data: [BalanceDataPoint]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            StatCard(title: "Average Balance", value: "92%")
            StatCard(title: "Best Session", value: "98%")
            StatCard(title: "Total Workouts", value: "24")
            StatCard(title: "Streak", value: "5 days")
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            ExerciseListView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell.fill")
                }
            
            StatsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
