import SwiftUI

struct ContentView: View {
    @ObservedObject var session = WatchSessionDelegate()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(session.routines) { routine in
                        NavigationLink {
                            RoutineDetailView(routine: routine)
                        } label: {
                            Text(routine.name)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.8))
                                )
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
            }
            .navigationTitle("내 루틴")
        }
    }
}

struct RoutineDetailView: View {
    let routine: Routine

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(routine.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reps: \(exercise.reps)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Weight: \(exercise.weight)kg")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
            }
            .padding()
        }
        .navigationTitle(routine.name)
    }
}
