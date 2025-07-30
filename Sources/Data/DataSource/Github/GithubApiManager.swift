//
//  GithubApiManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import Foundation

class GithubApiManager {
    private let urlRequestUtils = NetworkUtilities.shared
    private let session = URLSession.shared
    private let decoder = JSONDecoder()

    func getRepoContributors() async throws -> [Contributor] {
        let url = URL(string: "https://api.github.com/repos/tumble-for-kronox/Tumble-iOS/contributors")!
        let request = try urlRequestUtils.createGenericGetRequest(url: url)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let contributors = try decoder.decode([Contributor].self, from: data)
        return contributors
    }
}

