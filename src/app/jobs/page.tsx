export default function Jobs() {
  return (
    <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div className="px-4 py-6 sm:px-0">
        <h1 className="text-3xl font-bold text-gray-900">Ausbildungsplätze</h1>
        <p className="mt-2 text-sm text-gray-600">
          Finde deine passende Ausbildung.
        </p>
      </div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {/* Placeholder für Job-Cards */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-6">
            <h3 className="text-lg font-medium text-gray-900">Ausbildungsstelle 1</h3>
            <p className="mt-2 text-sm text-gray-600">Betrieb, Ort</p>
            <button className="mt-4 bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-md">
              Details
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}