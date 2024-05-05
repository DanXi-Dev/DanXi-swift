//
//  Weather.swift
//  Utils
//
//  Created by Kavin Zhao on 2024-04-09.
//

/*
import WeatherKit
import CoreLocation

public let HandanCampusLocation = CLLocation(latitude: 31.301911, longitude: 121.510771)
public let FenglinCampusLocation = CLLocation(latitude: 31.203908, longitude: 121.458458)
public let JiangwanCampusLocation = CLLocation(latitude: 31.34272, longitude: 121.513724)
public let ZhangjiangCampusLocation = CLLocation(latitude: 31.196204, longitude: 121.60448)

public class CampusWeather {
    public static let shared = CampusWeather()
    private init () {} // Prevent creation of other instances
    
    let weatherService = WeatherService()
    let classroomInitialToLocation: [Character: CLLocation] = ["H": HandanCampusLocation, "J": JiangwanCampusLocation, "F": FenglinCampusLocation, "Z": ZhangjiangCampusLocation]
    
    var weatherStore: [CLLocation: (Weather, Date)] = [:] // Campus -> (Weather, Expiration Date)
    
    private func getWeatherForLocation(_ location: CLLocation) async throws -> Weather {
        // Try get from cache
        if let (weather, expirationDate) = weatherStore[location] {
            if expirationDate > Date.now {
                return weather
            }
        }
        // Load from API
        let weather = try await weatherService.weather(for: location)
        weatherStore[location] = (weather, weather.hourlyForecast.metadata.expirationDate)
        return weather
    }
    
    public func getWeatherForClassroom(_ classroom: String) async throws -> Weather {
        guard !classroom.isEmpty else { throw WeatherError.noMatchingLocation }
        let location = classroomInitialToLocation[classroom[classroom.startIndex]]
        guard let location else { throw WeatherError.noMatchingLocation }
        return try await getWeatherForLocation(location)
    }
}

enum WeatherError: Error {
    case noMatchingLocation
}

*/