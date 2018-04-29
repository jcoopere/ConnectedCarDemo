import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.security.SecureRandom;
import java.util.Random;

public class CarPropertiesGenerator {
	
	private static final String DELIMITER = ","; 
	private static final SecureRandom sr = new SecureRandom();
	private static final Random r = new Random();

	public static void main(String[] args) {
		if (args.length != 2) {
			System.out.println("args: <number of vehicles> <output file path>");
			return;
		}
		
		int numVehicles = Integer.parseInt(args[0]);
		String outputFile = args[1];
		
		try {
			PrintWriter writer = new PrintWriter(outputFile, "UTF-8");
			
			for (int i = 0; i < numVehicles; i++) {
				StringBuilder carProps = new StringBuilder();
				
				carProps.append(generateVIN());
				carProps.append(DELIMITER);
				carProps.append(generateMiles());
				carProps.append(DELIMITER);
				carProps.append(generateAverageSpeed());
				carProps.append(DELIMITER);
				carProps.append(generateAverageAcceleration());
				carProps.append(DELIMITER);
				carProps.append(generateAverageDeceleration());
				carProps.append(DELIMITER);
				carProps.append(generateAverageCentripetalAcceleration());
				carProps.append(DELIMITER);
				carProps.append(generateIllegalLaneDepartureProbability());
				carProps.append(DELIMITER);
				carProps.append(generateCollisionProbabilityPer100000());				
				
				writer.println(carProps.toString());
			}

			writer.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	/**
	 * Generate vin (10 alphanumeric followed by 7 integers)
	 */
	private static String generateVIN() {
		StringBuilder sb = new StringBuilder();
		String vin = "";
		while (vin.length() != 10) {
			vin = new BigInteger(50, sr).toString(32).toUpperCase();
		}
		sb.append(vin);
		for (int i = 0; i < 7; i++) {
			sb.append(r.nextInt(10));
		}
		return sb.toString();
	}
	
	/**
	 * Generate starting mileage
	 */
	private static int generateMiles() {
		return r.nextInt(100000) + 500;
	}
	
	/**
	 * Generate average speed
	 */
	private static int generateAverageSpeed() {
		return r.nextInt(55) + 5;
	}
	
	/**
	 * Generate average acceleration
	 */
	private static double generateAverageAcceleration() {
		return r.nextDouble() * 1.5 + 1.0;
	}
	
	/**
	 * generate average deceleration
	 */
	private static double generateAverageDeceleration() {
		return r.nextDouble() * 1.25 + 0.5;
	}
	
	/**
	 * generate average centripetal (handling) acceleration
	 */
	private static double generateAverageCentripetalAcceleration() {
		return r.nextDouble() * 0.5 + 0.25;
	}
	
	/**
	 * generate average illegal lane departures per 100
	 */
	private static int generateIllegalLaneDepartureProbability() {
		return r.nextInt(90) + 1;
	}
	
	/**
	 * generate average collison probability per 100000 events
	 */
	private static int generateCollisionProbabilityPer100000() {
		return r.nextInt(3);
	}
}
